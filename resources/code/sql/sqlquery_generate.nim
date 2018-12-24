import strutils, times, os, db_postgres, logging


import ../utils/lognim


type
  ArgObj* = object
    val*: string
    isNull*: bool

  ArgsContainer = object
    query*: seq[ArgObj]
    args*: seq[string]

var dbNullVal*: ArgObj
dbNullVal.isNull = true


proc argType*(v: ArgObj): ArgObj =
  if v.isNull:
    return dbNullVal
  else:
    return v

proc argType*(v: string | int): ArgObj =
  var arg: ArgObj
  arg.isNull = false
  arg.val = $v
  return arg


proc argTypeSetNull*(v: ArgObj): ArgObj =
  if v.isNull:
    return dbNullVal
  elif v.val.len() == 0:
    return dbNullVal
  else:
    return v

proc argTypeSetNull*(v: string | int): ArgObj =
  var arg: ArgObj
  if len($v) == 0:
    return dbNullVal
  else:
    arg.isNull = false
    arg.val = $v
    return arg


proc dbValOrNullString*(v: string | int): string =
  ## Return NULL obj if len() == 0, else return value obj
  if len($v) == 0:
    return ""
  return v


proc dbValOrNull*(v: string | int): ArgObj =
  ## Return NULL obj if len() == 0, else return value obj
  if len($v) == 0:
    return dbNullVal
  var arg: ArgObj
  arg.val = $v
  arg.isNull = false
  return arg


template genArgs*[T](arguments: varargs[T, argType]): ArgsContainer =
  ## Create argument container for query and passed args
  var argsContainer: ArgsContainer
  argsContainer.query = @[]
  argsContainer.args = @[]
  for arg in arguments:
    let argObject = argType(arg)
    if argObject.isNull:
      argsContainer.query.add(argObject)
    else:
      argsContainer.query.add(argObject)
      argsContainer.args.add(argObject.val)
  argsContainer

template genArgsSetNull*[T](arguments: varargs[T, argType]): ArgsContainer =
  ## Create argument container for query and passed args
  var argsContainer: ArgsContainer
  argsContainer.query = @[]
  argsContainer.args = @[]
  for arg in arguments:
    let argObject = argTypeSetNull(arg)
    if argObject.isNull:
      argsContainer.query.add(argObject)
    else:
      argsContainer.query.add(argObject)
      argsContainer.args.add(argObject.val)
  argsContainer


#[
    Error handling
]#
template sqlErrorToLog(e: string) =
  ## If SQL fails send to logoutput
  var errorMsg = ""
  var count = 0
  for line in splitLines(e):
    if not isNilOrWhitespace(line) and line != "":
      inc(count)
      error("SQL " & $count & ") " & line)


#[
    Safe execution of queries
]#
proc getValueSafe*(db: DbConn, query: SqlQuery, args: varargs[string, `$`]): string =
  when not defined(dev):
    try:
      return getValue(db, query, args)
    except:
      sqlErrorToLog(getCurrentExceptionMsg())
      return ""

  when defined(dev):
    return getValue(db, query, args)

proc getValueSafe*(db: DbConn, stmtName: SqlPrepared, args: varargs[string, `$`]): string =
  when not defined(dev):
    try:
      return getValue(db, stmtName, args)
    except:
      sqlErrorToLog(getCurrentExceptionMsg())
      return ""

  when defined(dev):
    return getValue(db, stmtName, args)


proc getAllRowsSafe*(db: DbConn, query: SqlQuery, args: varargs[string, `$`]): seq[Row] =
  when not defined(dev):
    try:
      return getAllRows(db, query, args)
    except:
      sqlErrorToLog(getCurrentExceptionMsg())
      return @[]

  when defined(dev):
    return getAllRows(db, query, args)


proc getRowSafe*(db: DbConn, query: SqlQuery, args: varargs[string, `$`]): Row =
  when not defined(dev):
    try:
      return getRow(db, query, args)
    except:
      sqlErrorToLog(getCurrentExceptionMsg())
      return @[]

  when defined(dev):
    return getRow(db, query, args)


proc tryExecSafe*(db: DbConn; query: SqlQuery; args: varargs[string, `$`]): bool =
  when not defined(dev):
    try:
      return tryExec(db, query, args)
    except:
      sqlErrorToLog(getCurrentExceptionMsg())
      return false

  when defined(dev):
    return tryExec(db, query, args)

proc tryExecSafe*(db: DbConn; stmtName: SqlPrepared; args: varargs[string, `$`]): bool =
  when not defined(dev):
    try:
      return tryExec(db, stmtName, args)
    except:
      sqlErrorToLog(getCurrentExceptionMsg())
      return false

  when defined(dev):
    return tryExec(db, stmtName, args)


proc execSafe*(db: DbConn; query: SqlQuery; args: varargs[string, `$`]) =
  when not defined(dev):
    try:
      exec(db, query, args)
    except:
      sqlErrorToLog(getCurrentExceptionMsg())
      discard

  when defined(dev):
    exec(db, query, args)

proc execSafe*(db: DbConn; stmtName: SqlPrepared; args: varargs[string, `$`]) =
  when not defined(dev):
    try:
      exec(db, stmtName, args)
    except:
      sqlErrorToLog(getCurrentExceptionMsg())
      discard

  when defined(dev):
    exec(db, stmtName, args)


proc tryInsertIDSafe*(db: DbConn; query: SqlQuery; args: varargs[string, `$`]): int64 =
  when not defined(dev):
    try:
      return tryInsertID(db, query, args)
    except:
      sqlErrorToLog(getCurrentExceptionMsg())
      discard

  when defined(dev):
    return tryInsertID(db, query, args)

#[
    SAFE ESCAPING QOUTES
]#
proc sqlSafeChars*(escape: string): string =
  result = escape
  if contains(result, "\""):
    result = multiReplace(result, [("\"", "\"\"")])


proc sqlSafeCharToHTML*(escape: string): string =
  result = escape
  if contains(result, "\""):
    result = result.replace("\"", "&quot;")


proc sqlSafeCharsToFile*(escape: string): string =
  result = escape
  if contains(result, "\""):
    result = multiReplace(result, [("\"", "\"\"")])


#[
    GENERATING SQL QUERYS
]#
#[
proc sqlInsertTask*(table: string, data: varargs[string]): SqlQuery =
  var fields = "INSERT INTO " & table & " (rid, "
  var vals = ""
  for i, d in data:
    if i > 0:
      fields.add(", ")
      vals.add(", ")
    fields.add(d)
    vals.add('?')

  debug(fields & ") VALUES (?, " & vals & ")")
  result = sql(fields & ") VALUES (?, " & vals & ")")
]#

proc sqlInsert*(table: string, data: varargs[string], args: ArgsContainer.query): SqlQuery =
  ## SQL builder for INSERT queries
  ## Checks for NULL values
  var fields = "INSERT INTO " & table & " ("
  var vals = ""
  for i, d in data:
    if args[i].isNull:
      continue
    if i > 0:
      fields.add(", ")
      vals.add(", ")
    fields.add(d)
    vals.add('?')

  debug(fields & ") VALUES (" & vals & ")")
  result = sql(fields & ") VALUES (" & vals & ")")

proc sqlInsert*(table: string, data: varargs[string]): SqlQuery =
  ## SQL builder for INSERT queries
  ## Does NOT check for NULL values
  var fields = "INSERT INTO " & table & " ("
  var vals = ""
  for i, d in data:
    if i > 0:
      fields.add(", ")
      vals.add(", ")
    fields.add(d)
    vals.add('?')

  debug(fields & ") VALUES (" & vals & ")")
  result = sql(fields & ") VALUES (" & vals & ")")

proc sqlUpdate*(table: string, data: varargs[string], where: varargs[string]): SqlQuery =
  ## SQL builder for UPDATE queries
  ## Does NOT check for NULL values
  var fields = "UPDATE " & table & " SET "
  for i, d in data:
    if i > 0:
      fields.add(", ")
    fields.add(d & " = ?")
  var wes = " WHERE "
  for i, d in where:
    if i > 0:
      wes.add(" AND ")
    wes.add(d & " = ?")

  debug(fields & wes)
  result = sql(fields & wes)

proc sqlUpdate*(table: string, data: varargs[string], where: varargs[string], args: ArgsContainer.query): SqlQuery =
  ## SQL builder for UPDATE queries
  ## Checks for NULL values
  var fields = "UPDATE " & table & " SET "
  for i, d in data:
    if i > 0:
      fields.add(", ")
    if args[i].isNull:
      fields.add(d & " = NULL")
    else:
      fields.add(d & " = ?")
  var wes = " WHERE "
  for i, d in where:
    if i > 0:
      wes.add(" AND ")
    wes.add(d & " = ?")

  debug(fields & wes)
  result = sql(fields & wes)

proc sqlDelete*(table: string, where: varargs[string]): SqlQuery =
  ## SQL builder for DELETE queries
  ## Does NOT check for NULL values
  var res = "DELETE FROM " & table
  var wes = " WHERE "
  for i, d in where:
    if i > 0:
      wes.add(" AND ")
    wes.add(d & " = ?")

  debug(res & wes)
  result = sql(res & wes)

proc sqlDelete*(table: string, where: varargs[string], args: ArgsContainer.query): SqlQuery =
  ## SQL builder for DELETE queries
  ## Checks for NULL values
  var res = "DELETE FROM " & table
  var wes = " WHERE "
  for i, d in where:
    if i > 0:
      wes.add(" AND ")
    if args[i].isNull:
      wes.add(d & " = NULL")
    else:
      wes.add(d & " = ?")

  debug(res & wes)
  result = sql(res & wes)

proc sqlRead*(table: string, data: varargs[string], left: varargs[string], whereC: varargs[string], access: string, accessC: string, order: varargs[string]): SqlQuery =
  var res = "SELECT "
  for i, d in data:
    if i > 0: res.add(", ")
    res.add(d)
  var lef = ""
  for i, d in left:
    if d != "":
      lef.add(" LEFT JOIN ")
      lef.add(d)
  var wes = ""
  for i, d in whereC:
    if d != "" and i == 0:
      wes.add(" WHERE ")
    if i > 0:
      wes.add(" AND ")
    if d != "":
      wes.add(d & " = ?")
  var acc = ""
  if access != "":
    if wes.len == 0:
      acc.add(" WHERE " & accessC & " in ")
      acc.add("(")
    else:
      acc.add(" AND " & accessC & " in (")
    for a in split(access, ","):
      acc.add(a & ",")
    acc = acc[0 .. ^2]
    acc.add(")")
  var ord = ""
  for i, d in order:
    if d != "" and i == 0:
      ord.add(" ORDER BY ")
    if i > 0:
      ord.add(", ")
    if d != "":
      ord.add(d)

  debug(res & " FROM " & table & lef & wes & acc & ord)
  result = sql(res & " FROM " & table & lef & wes & acc & ord)

proc sqlSelect*(table: string, data: varargs[string], left: varargs[string], whereC: varargs[string], access: string, accessC: string, user: string): SqlQuery =
  ## SQL builder for SELECT queries
  ## Does NOT check for NULL values
  var res = "SELECT "
  for i, d in data:
    if i > 0: res.add(", ")
    res.add(d)
  var lef = ""
  for i, d in left:
    if d != "":
      lef.add(" LEFT JOIN ")
      lef.add(d)
  var wes = ""
  for i, d in whereC:
    if d != "" and i == 0:
      wes.add(" WHERE ")
    if i > 0:
      wes.add(" AND ")
    if d != "":
      wes.add(d & " ?")
  var acc = ""
  if access != "":
    if wes.len == 0:
      acc.add(" WHERE " & accessC & " in ")
      acc.add("(")
    else:
      acc.add(" AND " & accessC & " in (")
    for a in split(access, ","):
      acc.add(a & ",")
    acc = acc[0 .. ^2]
    acc.add(")")

  debug(res & " FROM " & table & lef & wes & acc & " " & $user)
  result = sql(res & " FROM " & table & lef & wes & acc & " " & user)

proc sqlSelect*(table: string, data: varargs[string], left: varargs[string], whereC: varargs[string], access: string, accessC: string, user: string, args: ArgsContainer.query): SqlQuery =
  ## SQL builder for SELECT queries
  ## Checks for NULL values
  var res = "SELECT "
  for i, d in data:
    if i > 0: res.add(", ")
    res.add(d)
  var lef = ""
  for i, d in left:
    if d != "":
      lef.add(" LEFT JOIN ")
      lef.add(d)
  var wes = ""
  for i, d in whereC:
    if d != "" and i == 0:
      wes.add(" WHERE ")
    if i > 0:
      wes.add(" AND ")
    if d != "":
      if args[i].isNull:
        wes.add(d & " NULL")
      else:
        wes.add(d & " ?")
  var acc = ""
  if access != "":
    if wes.len == 0:
      acc.add(" WHERE " & accessC & " in ")
      acc.add("(")
    else:
      acc.add(" AND " & accessC & " in (")
    for a in split(access, ","):
      acc.add(a & ",")
    acc = acc[0 .. ^2]
    acc.add(")")

  debug(res & " FROM " & table & lef & wes & acc & " " & $user)
  result = sql(res & " FROM " & table & lef & wes & acc & " " & user)