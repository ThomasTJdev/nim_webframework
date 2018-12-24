import asyncdispatch, smtp, strutils, os, htmlparser, asyncnet, parsecfg, times

var dict = loadConfig(getAppDir() & "/config/config.cfg")


let adminEmail = dict.getSectionValue("Person","AdminEmail")

let smtpAddress    = dict.getSectionValue("SMTP","SMTPAddress")
let smtpPort       = dict.getSectionValue("SMTP","SMTPPort")
let smtpFrom       = dict.getSectionValue("SMTP","SMTPFrom")
let smtpUser       = dict.getSectionValue("SMTP","SMTPUser")
let smtpPassword   = dict.getSectionValue("SMTP","SMTPPassword")

let testAccountEmail = dict.getSectionValue("Testaccount", "testAccountEmail")

let host* = dict.getSectionValue("Server","hostname")
let hostTitle* = dict.getSectionValue("Server","title")

proc sendMailNow*(subject, message, recipient: string) {.async.} =
  ## Send the email through smtp

  when defined(dev) and not defined(devemailon):
    echo "Dev is true, email is not send"
    return

  if testAccountEmail == recipient:
    echo "Not possible to send mails to testuser"
    return

  if smtpAddress.len() == 0:
    echo "No SMTP address has been specified. Email was not send."
    return

  const otherHeaders = @[("Content-Type", "text/html; charset=\"UTF-8\"")]

  var client = newAsyncSmtp(useSsl = true)
  await client.connect(smtpAddress, Port(parseInt(smtpPort)))
  await client.auth(smtpUser, smtpPassword)

  let from_addr = smtpFrom
  let toList = @[recipient]

  var headers = otherHeaders
  headers.add(("From", from_addr))

  let encoded = createMessage(subject, message, toList, @[], headers)

  try:
    await client.sendMail(from_addr, toList, $encoded)

  except:
    echo "Error in sending mail: " & recipient

  when defined(dev):
    echo "Email send"


proc sendAdminMailNow*(subject, message: string) {.async.} =
  ## Send the email through smtp
  ## Clean admin mailing

  let recipient = adminEmail
  let from_addr = smtpFrom
  const otherHeaders = @[("Content-Type", "text/html; charset=\"UTF-8\"")]

  when defined(dev):
    echo "Dev is true, email is not send"
    return

  var client = newAsyncSmtp(useSsl = true, debug = false)

  await client.connect(smtpAddress, Port(parseInt(smtpPort)))

  await client.auth(smtpUser, smtpPassword)

  let toList = @[recipient]

  var headers = otherHeaders
  headers.add(("From", from_addr))

  let encoded = createMessage("Admin - " & subject, message,
      toList, @[], headers)

  await client.sendMail(from_addr, toList, $encoded)

  when defined(dev):
    echo "Admin email send"

