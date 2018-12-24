import os, strutils, db_postgres, rdstdin, logging


import ../password/password_generate
import ../password/password_hash
import ../password/salt_generate
import ../sql/sqlquery_generate
import ../utils/lognim


proc createAdminUser*(db: DbConn): bool =
  ## Create new admin user
  ## Input is done through stdin

  let iName = readLineFromStdin "Input admin name:     "
  let iEmail = readLineFromStdin "Input admin email:    "
  let iPwd = readLineFromStdin "Input admin password: "
  let iAdminType = readLineFromStdin "Type (Admin or AdminSys): "

  if iName.len() == 0 or iEmail.len() == 0 or iPwd.len() == 0:
    fatal("Missing input")
    return false
  if iAdminType notin ["Admin", "AdminSys"]:
    fatal("Admin type needs to be either Admin or AdminSys")
    return false

  let salt = makeSalt()
  let password = makePassword(iPwd, salt)

  let newCompany = tryInsertID(db, sqlInsert("company", ["name"]), iAdminType)
  discard tryInsertID(db, sqlInsert("company_access", ["company_id"]), newCompany)

  let newUser = tryInsertID(db, sqlInsert("person", ["name", "email", "password", "salt", "status", "company_id"]), $iName, $iEmail, password, salt, iAdminType, newCompany)

  let newPersonAccess = tryInsertID(db, sqlInsert("person_access", ["user_id", "company_id", "status"]), newUser, newCompany, iAdminType)

  if newCompany > 0 and newUser > 0 and newPersonAccess > 0:
    return true
  else:
    fatal("Something went wrong")
    return false