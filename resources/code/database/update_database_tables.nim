import db_postgres
import strutils


import ../sqlquery/sqlquery_generate
import ../utils/logging


proc updateDatabaseTables*(db: DbConn, version: string) =
  ## Updates the main database with new tables e.g. based on the
  ## the current version

  case version

  of "1.0.0":
    discard
    #[
    if tryExec(db, sql"ALTER TABLE actions ADD COLUMN IF NOT EXISTS assigned_to_userid INTEGER"):
      dbg("INFO", "updateDatabaseTabels() version 1.0.0 has been updated [ADD assigned_to_userid]")
    else:
      dbg("ERROR", "updateDatabaseTabels() version 1.0.0 could not be updated [ADD assigned_to_userid]")


    if tryExec(db, sql"ALTER TABLE actions ALTER COLUMN assigned_to TYPE VARCHAR(200)"):
      dbg("INFO", "updateDatabaseTabels() version 1.0.0 has been updated [INT to VARCHAR]")
    else:
      dbg("ERROR", "updateDatabaseTabels() version 1.0.0 could not be updated [INT to VARCHAR]")
    ]#

  of "1.0.1":
    discard

    #[
      ALTER TABLE actions ADD COLUMN IF NOT EXISTS cx_testitem INTEGER;
    ]#
      

  else:
    dbg("INFO", "updateDatabaseTabels() nothing to update")
    discard