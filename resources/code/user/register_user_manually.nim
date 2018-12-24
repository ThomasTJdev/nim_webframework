import asyncdispatch
import cgi
import db_postgres
import logging
import os
import parsecfg
import strutils
import times

from jester import makeUri, Request

import ../email/email_admin
import ../email/email_templates
import ../password/password_generate
import ../password/password_hash
import ../password/salt_generate
import ../sql/sqlquery_generate
import ../user/user_ranks
import ../utils/lognim
import ../utils/random_generator


let dict = loadConfig(getAppDir() & "/config/config.cfg")
let minPassLength = parseInt(dict.getSectionValue("Useradministration","MinPassLength"))


proc registerManual*(db: DbConn, uncleReq: Request, uncleRank: Rank, uncleCompanyID, uncleUserID, uncleName, name, emailRaw, company, rank, timezone, language, sysAccessCompanyID: string): Future[tuple[b: bool, s: string, c: string]] {.async.} =
  ## Manual registration of new

  # Privileges check
  if uncleRank notin [AdminSys, Admin, Moderator]:
    return (false, "You are not allowed to add new users", "")

  if uncleRank == Moderator and rank == "Admin":
    return (false, "You can not add an Admin", "")

  if rank notin ["Admin", "Moderator", "User", "Viewer", "Deactivated"]:
    return (false, "Wrong status", "")


  # Email validation
  if not ('@' in emailRaw and '.' in emailRaw):
    return (false, "Invalid email address", "")
  let email = replace(toLowerAscii(emailRaw), " ", "")


  # Set company
  let assignCompanyID = if uncleRank == AdminSys: sysAccessCompanyID else: uncleCompanyID


  # Check that theres no other with that email
  let emailExistsID = getValueSafe(db, sqlSelect("person", ["id"], [""], ["email ="], "", "", ""), email)
  if emailExistsID.len() != 0:
    # Give access to company id
    discard tryInsertID(db, sqlInsert("person_access", ["user_id", "company_id", "status"]), emailExistsID, assignCompanyID, rank)
    return (true, "User now has access to your company", "")


  # Check username
  if name.len < 3:
    return (false, "Invalid username! The username needs to consists of atleast 3 characters", "")


  # Check for language
  var languageCheck = if language notin ["EN", "DA"]: "EN" else: language


  # Generate password:
  let password = randomString(12)
  var salt = makeSalt()
  let passwordCrypt = makePassword(password, salt)


  # Insert new user
  debug("Adding new user")
  let uncleCompanyName = getValueSafe(db, sqlSelect("person", ["company"], [""], ["id ="], "", "", ""), uncleUserID)
  var newUser = tryInsertID(db,
        sqlInsert("person", ["name", "password", "email", "salt", "status", "company_id", "company", "timezone", "language", "registration_status"]),
        name, passwordCrypt, email, salt, "EmailUnconfirmed", assignCompanyID, uncleCompanyName, timezone, languageCheck, rank)


  # Give access to company id
  discard tryInsertID(db,
        sqlInsert("person_access", ["user_id", "company_id", "status"]),
        newUser, assignCompanyID, rank)


  # Generate activation email
  if newUser > 0:
    debug("New user created. Generating activation email.")

    # Send activation email.
    let epoch = $int(epochTime())
    let ident = makeIdentHash(name, passwordCrypt, epoch, salt, rank)
    let activateUrl = uncleReq.makeUri("/activateEmail?name=$1&epoch=$2&ident=$3&id=$4&manual=$5" %
        [encodeUrl(name), encodeUrl(epoch),
         encodeUrl(ident), encodeUrl($newUser), encodeUrl(rank)])

    # Save url for validation when clicking on the activation
    execSafe(db, sqlUpdate("person", ["secretUrl"], ["id"]), ident, newUser)
    when defined(dev):
      echo activateUrl

    # Sending email
    debug("Activation email sending")
    let emailSentFut = sendEmailActivationManual(languageCheck, email, name, password, activateUrl, uncleName)
    while not emailSentFut.finished:
      poll()
    when not defined(dev):
      if emailSentFut.failed:
        warn("registerManual(): Couldn't send activation email: " & emailSentFut.error.msg)
        return (false, "Something went wrong sending the activation email. Please contact the systemadministrator", "")

    # Notify admin about new user
    when defined(adminnotify) and not defined(dev):
      discard sendEmailAdminNewUserAdded(languageCheck, email, name, uncleName, $uncleVirtualDB)

    return (true, $newUser, assignCompanyID)

  else:
    warn("registerManual(): Error adding a new user.")
    return (false, "ERROR", "")