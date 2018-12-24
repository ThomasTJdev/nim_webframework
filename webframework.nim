##
##
##        TTJ
##        (c) Copyright 2019 Thomas Toftgaard Jarløv
##        All rights reserved.
##
##
##
import
  asyncdispatch,
  asyncnet,
  bcrypt,
  db_postgres,
  jester,
  logging,
  macros,
  os,
  parsecfg,
  parseutils,
  postgres,
  random,
  recaptcha,
  strutils,
  times


import resources/code/database/create_adminuser
import resources/code/database/create_database

import resources/code/email/email_connection
import resources/code/email/email_admin

import resources/code/password/password_generate
import resources/code/password/password_hash
import resources/code/password/password_set_user
import resources/code/password/salt_generate

import resources/code/sql/sqlquery_generate

import resources/code/user/register_user_manually
import resources/code/user/reset_user_password
import resources/code/user/user_ranks

import resources/code/utils/dates
import resources/code/utils/google_recaptcha
import resources/code/utils/lognim
import resources/code/utils/random_generator

type
  ## TSession - parent of TData
  TSession* = object of RootObj
    loggedIn*: bool
    page*: string
    rank*: Rank
    username*, userpass*, email*: string

  TData* = ref object of TSession
    errorMsg*, loginErrorMsg*, invalidField*, message*: string
    req*: Request
    companyid*: string
    companyview*: string
    lang*: string
    userid*: string
    timezone*: string

macro readCfgAndBuildSource*(cfgFilename: string): typed =
  ## Generate const from config file
  let inputString = slurp(cfgFilename.strVal)
  var source = ""

  for line in inputString.splitLines:
    # Ignore empty lines
    if line.len < 1 and line.substr(0, 0) != "[": continue
    var chunks = split(line, " = ")
    if chunks.len != 2:
      continue

    source &= "const cfg" & chunks[0] & "= \"" & chunks[1] & "\"\n"

  if source.len < 1: error("Input file empty!")
  echo "Constant vars compiled from configStatic.cfg:"
  echo source
  result = parseStmt(source)

readCfgAndBuildSource("/config/configStatic.cfg")


#[
  ##
  ##
  ##    Constants, let's and var's
  ##
  ##
]#
include resources/code/init/init_configfile
var db: DbConn


#[
  ##
  ##
  ##    Jester settings
  ##
  ##
]#
settings:
  port = Port(mainPort)
  bindAddr = mainURL


#[
  ##
  ##
  ##    Empty out user assigned data (c: var TData)
  ##
  ##
]#
proc init(c: var TData) =
  ## Empty out user session data

  c.userpass      = ""
  c.username      = ""
  c.userid        = ""
  c.companyid     = ""
  c.companyview   = ""
  c.timezone      = ""
  c.message       = ""
  c.errorMsg      = ""
  c.loginErrorMsg = ""
  c.invalidField  = ""
  c.loggedIn      = false


#[
  ##
  ##
  ##    Generic response
  ##
  ##
]#
proc setError(c: var TData, field, msg: string): bool {.inline.} =
  c.invalidField = field
  c.errorMsg = "Error: " & msg
  return false

proc genericMessage(c: var TData): string =
  if c.errorMsg.len() != 0:
    return "<div style='color:#fc6969;text-align: center;font-size: 2.5rem; line-height: 3rem;'><b>" & c.errorMsg & "</b></div>"

  if c.message.len() != 0:
    return "<div style='color:#15a124ce;text-align: center;font-size: 2rem; line-height: 2.6rem;'><b>" & c.message & "</b></div>"



#[
  ##
  ##
  ##    Check user status
  ##
  ##
]#
proc getBanErrorMsg*(rank: Rank): string =
  ## Get user status and check for ban

  case rank
  of Deactivated:
    return "Your account has been deactivated. Please contact your company's administrator."
  of EmailUnconfirmed:
    return "You need to confirm your email first. Please check your inbox. It can take up to 5 minutes, before you receive the email."
  of Viewer, User, Moderator, Admin, AdminSys:
    return ""



#[
  ##
  ##
  ##    Check if the user is signed ind
  ##
  ##
]#
proc loggedIn(c: TData): bool =
  ## Check if user is logged in
  ## by verifying that c.username != 0

  result = c.username.len() > 0

proc checkLoggedIn(c: var TData) =
  ## Check if user is logged in

  if not c.req.cookies.hasKey("sid"): return
  let pass = c.req.cookies["sid"]
  if execAffectedRows(db, sql("update session SET lastModified = " & $toInt(epochTime()) & " " & "WHERE ip = ? AND password = ?"), c.req.ip, pass) > 0:
    c.userpass = pass
    c.userid = getValueSafe(db, sql"SELECT userid FROM session WHERE ip = ? AND password = ?", c.req.ip, pass)

    let row = getRowSafe(db, sql"SELECT person.name, person.email, person.status, person.language, person.company_id, person.timezone, company.name FROM person LEFT JOIN company ON company.id = person.company_id WHERE person.id = ?", c.userid)
    c.username = row[0]
    c.email = toLowerAscii(row[1])
    c.rank = parseEnum[Rank](row[2])
    let ban = getBanErrorMsg(c.rank)
    if ban.len() > 0:
      c.loggedIn = false
      return
    c.lang = row[3]
    c.companyid = row[4]
    c.timezone = if row[5].len() == 0: "0" else: row[5]
    c.companyview = row[6]

    discard tryExecSafe(db, sqlUpdate("person", ["lastOnline"], ["id"]), toInt(epochTime()), c.userid)

  else:
    c.loggedIn = false


#[
  ##
  ##
  ##    Login / Logout
  ##
  ##
]#
proc login(c: var TData, email, pass: string): bool =
  ## User login

  # Check access
  if email.len == 0:
    return c.setError("email", "Email cannot be empty.")

  var success = false

  for row in fastRows(db, sql"SELECT person.id, person.name, person.password, person.email, person.salt, person.status, person.company_id, person.timezone, company.name FROM person LEFT JOIN company ON company.id = person.company_id WHERE email = ?", replace(toLowerAscii(email), " ", "")):

    # If password match, assign DB results to user
    if row[2] == makePassword(pass, row[4], row[2]):
      c.rank = parseEnum[Rank](row[5])
      let ban = getBanErrorMsg(c.rank)
      if ban.len() > 0:
        return c.setError("name", ban)
      c.userid = row[0]
      c.username = row[1]
      c.userpass = row[2]
      c.email = toLowerAscii(row[3])
      c.companyid = row[6]
      c.timezone = row[7]
      c.companyview = row[8]

      success = true
      break

  if success:
    # create session:
    execSafe(db, sql"insert into session (ip, password, userid) values (?, ?, ?)", c.req.ip, c.userpass, c.userid)
    info("INFO", "Login successful")
    return true

  else:
    info("INFO", "Login failed")
    return c.setError("password", "Login failed!")


proc logout(c: var TData) =
  ## Logout of the platform

  const query = sql"delete from session where ip = ? and password = ?"
  c.username = ""
  c.userpass = ""
  execSafe(db, query, c.req.ip, c.req.cookies["sid"])


#[
  ##
  ##
  ##    Login check
  ##
  ##
]#
template createTFD() =
  ## Check if logged in and assign data to user

  var c {.inject.}: TData
  new(c)
  init(c)
  c.req = request
  if request.cookies.len > 0:
    checkLoggedIn(c)
  c.loggedIn = loggedIn(c)


#[
  ##
  ##
  ##    Main procs
  ##
  ##
]#
proc mainRunDetails() =
  info("INFO", "Main module started at: " & $getTime())
  echo ""
  echo "--------------------------------------------"
  echo "  Package:       " & cfgPackageName
  echo "  Version:       " & cfgPackageVersion & " - " & cfgPackageDate
  echo "  Description:   " & cfgPackageDescription
  echo "  Author name:   " & cfgAuthorName
  echo "  Author email:  " & cfgAuthorEmail
  echo "  License owner: " & cfgCustomerLicenseOwner
  echo "  License key:   " & cfgCustomerLicenseKey
  echo "  Current time:  " & $getTime()
  echo "--------------------------------------------"
  echo ""

proc mainConnectDB() =
  try:
    db = open("", "", "", "host=" & db_path & " port=5432 dbname=" & db_name & " user=" & db_user & " password=" & db_pass)
    info("Connection to DB is established")
  except:
    fatal("Connection to DB could not be established")
    quit()


#[
  ##
  ##
  ##    Templates
  ##
  ##
]#
# User templates
include "resources/tmpl/user/user_add.tmpl"
include "resources/tmpl/user/user_edit.tmpl"
include "resources/tmpl/user/user_login.tmpl"
include "resources/tmpl/user/user_register.tmpl"
include "resources/tmpl/user/user_reset_password.tmpl"
include "resources/tmpl/user/users.tmpl"

# AdminSys
include "resources/tmpl/company/company_adminsys.tmpl"

# Company
include "resources/tmpl/company/company.tmpl"

# General templates
include "resources/tmpl/general/sidebar.tmpl"
include "resources/tmpl/general/import_libraries.tmpl"
include "resources/tmpl/general/frontpage.tmpl"
include "resources/tmpl/general/main.tmpl"


#[
  ##
  ##
  ##    Main
  ##
  ##
]#
when isMainModule:
  mainConnectDB()

  let args = multiReplace(commandLineParams().join(" "), [("-", ""), (" ", "")])
  case args
  of " ":
    discard
  of "help":
    echo "No help available"
  of "createadmin":
    if not createAdminUser(db):
      quit()
  of "createdb":
    createDatabase(db)
  else:
    discard

  if args.len() != 0:
    quit(0)

  mainRunDetails()


#[
  ##
  ##
  ##    Routes
  ##
  ##
]#
# Include routes
include "resources/routes/routes_company.nim"
include "resources/routes/routes_users.nim"
include "resources/routes/routes_general.nim"
include "resources/routes/routes_sys_company.nim"

# Extend routes
routes:
  extend users, ""
  extend general, ""
  extend company, ""
  extend sysCompany, ""