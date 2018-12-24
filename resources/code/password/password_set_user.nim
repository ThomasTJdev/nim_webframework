# Copyright 2018 - Thomas T. Jarløv

import db_postgres


import ../password/password_generate
import ../password/salt_generate
import ../sql/sqlquery_generate


proc newPassword*(db: DbConn, userID, pass: string, minPassLength: int): bool =
  ## Generate new password and updates user
  ## Checks password lenght first

  var salt = makeSalt()
  let password = makePassword(pass, salt)
  if pass.len < minPassLength:
    return false

  return tryExecSafe(db, sqlUpdate("person", ["password", "salt"], ["id"]), password, salt, userID)


proc newPasswordSet*(db: DbConn, userID, pass: string, minPassLength: int): tuple[res: bool, msg: string] =
  ## Generate new password and updates user
  ## Checks password lenght first

  var salt = makeSalt()
  let password = makePassword(pass, salt)
  if pass.len < minPassLength:
    return (false, "Your passwords needs to be more than " & $minPassLength)

  return (tryExecSafe(db, sqlUpdate("person", ["password", "salt"], ["id"]), password, salt, userID), "")
