# Copyright 2018 - Thomas T. Jarløv
import asyncdispatch, smtp, strutils, os, htmlparser, asyncnet, parsecfg

import ../email/email_connection

from times import getTime, getGMTime, format

const hostTitle = "WF main"

proc sendEmailActivation*(email, user, activateUrl: string) {.async.} =
  ## Send the actication email

  let message = """Hello $1,
<br><br>
You have recently registered an account on $3.
<br><br>
As the final step in your registration, we require that you confirm your email
via the following link:
<br>
  $2
<br><br>
Please do not hesitate to contact us at $5, if you have any questions.
<br><br>
Thank you for registering and becoming a part of $4!""" % [user, activateUrl, host, hostTitle, "contact@mail.com"]

  await sendMailNow(hostTitle & " Email Confirmation", message, email)



proc sendEmailActivationManual*(language, email, user, password, activateUrl, invitor: string) {.async.} =
  ## Send the activation email, when admin added a new user

  let message = """Hello $1,
<br><br>
You have been invited to join $2 platform at $6.
<br><br>
$7 is a browser based system for managing multiple projects and personal to-do items.
<br><br>
As the final step in your registration, we require that you confirm your email
via the following link:
  <br>
  $5
  <br><br>
To login use the details below. On your first login, please navigate to your settings and change your password!
<br>
Email:    $3
<br>
Password: $4
<br><br>
Please do not hesitate to contact us at $8, if you have any questions.
<br><br>
Thank you for registering and becoming a part of $7!""" % [user, invitor, email, password, activateUrl, host, hostTitle, "contact@mail.com"]

  await sendMailNow(hostTitle & " Email Confirmation", message, email)


proc sendEmailResetUserPassword*(name, email, resetUrl: string) {.async.} =
  ## Send the actication email

  let message = """Hello $2,
<br><br>
A request for resetting your password on $1 has been sent.
<br><br>
If you did not make this request, you can safely ignore this email.
A password request can be made by anyone, and this does not mean
or indicate, that your account is in any danger of being accessed
by someone else.
<br><br>
If you do actually want to reset your password, please visit the link:
<br>
  $4
<br><br>
Thank you for being a part of $1!""" % [host, name, email, resetUrl]

  await sendMailNow(hostTitle & " - Reset password", message, email)