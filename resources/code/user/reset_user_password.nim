import strutils
import db_postgres
import asyncdispatch
import times
import logging
import cgi
import recaptcha

from jester import makeUri, Request

import ../email/email_templates
import ../password/password_hash
import ../sql/sqlquery_generate
import ../utils/lognim
import ../utils/google_recaptcha


proc resetUserPassword*(db: DbConn, req: Request, email, antibot, userIP: string): Future[tuple[b: bool, s: string]]  {.async.} =
  ## Reset the users password

  # reCAPTCHA validation:
  when not defined(dev):
    if not await checkReCaptcha(antibot, userIP):
      return (false, "Error. You need to verify, that you are not a robot!")

  # Gather some extra information to determine ident hash.
  let epoch = $int(epochTime())
  let row = db.getRow(sql"select password, salt, name from person where email = ?", email)

  try:
    if row[0] == "":
      return (false, "Error. There is a problem with your account. Please contact support.")
  except:
    return (false, "Error. There is a problem with your account. Please contact support.")

  let ident = makeIdentHash(row[2], row[0], epoch, row[1])

  # Generate URL for the email.
  # TODO: Get rid of the stupid `%` in main.tmpl as it screws up strutils.%
  let resetUrl = req.makeUri(
      strutils.`%`("/emailResetPassword?name=$1&epoch=$2&ident=$3",
          [encodeUrl(row[2]), encodeUrl(epoch),
           encodeUrl(ident)]))

  debug("Reset url for " & email & " is: " & resetUrl)

  # Send the email.
  let emailSentFut = sendEmailResetUserPassword(row[2], email, resetUrl)
  # TODO: This is a workaround for 'var T' not being usable in async procs.
  while not emailSentFut.finished:
    poll()
  if emailSentFut.failed:
    error("resetUserPassword(): Couldn't send activation email to: " & email & ". Errorcode: " & emailSentFut.error.msg)
    #return setError(c, "email", "Couldn't send activation email")
    return (false, "Error. The reset email could not be send. Please try again.")

  return (true, "")