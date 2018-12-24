import parsecfg, os, strutils


# Using config.ini
let dict = loadConfig("config/config.cfg")


# Software
let filename = dict.getSectionValue("Software","filename")
let configIdent = dict.getSectionValue("Software","configIdent")


# Database settings
when defined(release):
  let db_path = dict.getSectionValue("Database","path")
  let db_pass = dict.getSectionValue("Database","pass")
  let db_user = dict.getSectionValue("Database","user")
  let db_name = dict.getSectionValue("Database","name")
when not defined(release):
  let db_path = dict.getSectionValue("Database","pathdev")
  let db_pass = dict.getSectionValue("Database","passdev")
  let db_user = dict.getSectionValue("Database","userdev")
  let db_name = dict.getSectionValue("Database","namedev")


# Logfile
when defined(release):
  let logfile = dict.getSectionValue("Logging","logfile")
when not defined(release):
  let logfile = dict.getSectionValue("Logging","logfiledev")


# Server settings
let mainURL = dict.getSectionValue("Server","url")
let mainPort = parseInt dict.getSectionValue("Server","port")
let title = dict.getSectionValue("Server","title")
let hostname = dict.getSectionValue("Server","hostname")


# Proxy settings
let proxyURL = dict.getSectionValue("Proxy","url")
let proxyPath = dict.getSectionValue("Proxy","path")


# Settings
let openRegistration = parseBool(dict.getSectionValue("Settings","openRegistration"))
let multipleCompanies = parseBool(dict.getSectionValue("Settings","multipleCompanies"))

# Contact persons
let supportEmail = dict.getSectionValue("Person","SupportEmail")


# User administration
let minPassLength = parseInt(dict.getSectionValue("Useradministration","MinPassLength"))


# Google Analytics
let googleAnalytics = dict.getSectionValue("Analytics","GoogleAnalytics")