import bcrypt, strutils, db_postgres

import ../sql/sqlquery_generate


proc makeIdentHash*(user, password, epoch, secret: string, manual = "", comparingTo = ""): string =
  ## Creates a hash verifying the identity of a user. Used for password reset
  ## links and email activation links.
  ## If ``epoch`` is smaller than the epoch of the user's last login then
  ## the link is invalid.
  ## The ``secret`` is the 'salt' field in the ``person`` table.

  let bcryptSalt = if comparingTo != "": comparingTo else: genSalt(8)
  result = hash(manual & user & password & epoch & secret, bcryptSalt)




proc verifyIdentHashRegister*(db: DbConn, id, name, password, epoch, salt, manual, ident: string): bool =
  ## Verifying ident hash for registration mail

  let row = getValueSafe(db, sqlSelect("person", ["lastOnline"], [""], ["id ="], "", "", ""), id)
  if row == "": return false
  let newIdent = makeIdentHash(name, password, epoch, salt, manual, ident)
  # Check that the user has not been logged in since this ident hash has been created. Give the timestamp a certain range to prevent false negatives.
  var lastOnline: int
  try:
    lastOnline = parseInt(row)
  except:
    lastOnline = parseInt(split(row, ".")[0])

  if lastOnline > (epoch.parseInt + 60): return false

  result = newIdent == ident




proc verifyIdentHashReset*(db: DbConn, name, epoch, ident: string): bool =
  ## Verifying ident hash for reset mail

  const query = sql"select password, salt, lastOnline from person where name = ?"

  try:
    var row = getRow(db, query, name)

    if row[0] == "":
      return false

    let newIdent = makeIdentHash(name, row[0], epoch, row[1], "", ident)

    # Check that the user has not been logged in since this ident hash has been
    # created. Give the timestamp a certain range to prevent false negatives.
    if row[2].parseInt > (epoch.parseInt + 60):
      return false

    result = newIdent == ident

  except:
    return false