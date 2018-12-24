import asyncdispatch, smtp, strutils, os, htmlparser, asyncnet, parsecfg
from times import getTime, getGMTime, format


import ../email/email_connection


proc sendEmailAdminError*(msg: string) {.async.} =
  ## Send email - user removed

  let message = """Hi Admin
<br><br>
An error occured.
<br><br>
$1
<br><br>
""" % [msg]

  await sendAdminMailNow("Admin: Error occurred", message)


proc sendEmailAdminInfo*(msg: string) {.async.} =
  ## Send email - user removed

  let message = """Hi Admin
<br><br>
Info:
<br><br>
$1
<br><br>
""" % [msg]

  await sendAdminMailNow("Admin: Info", message)

