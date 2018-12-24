import os
import macros
import parsecfg
import strutils
import tables

#import ../manual/manual_check
import ../plugin/plugin_utils
import ../utils/logging


macro pluginsLanguageFile(): untyped =
  ## Macro to include plugins custom language files

  var extensions = "const langAll = \"\"\""
  for ppath in pluginsPath:
    if fileExists(ppath & "/config/languageFile.cfg"):
      extensions.add(staticRead(ppath & "/config/languageFile.cfg") & "\n")

  # Include core language file last, so plugins can override
  extensions.add(staticRead("../../../config/languageFile.cfg") & "\n")

  when defined(dev):
    echo "Plugins - include language:"
    echo if extensions.len() == 0: "- nothing" else: "Language included"

  result = parseStmt(extensions & "\"\"\"")

pluginsLanguageFile()


let dict = loadConfig(getAppDir() & "/config/config.cfg")
#let standardLanguage = manualLanguage()
let standardLanguage = if dict.getSectionValue("Language","standard").len() == 0: "EN" else: dict.getSectionValue("Language","standard")

proc langTableInit(): Table[string, string] =
  ## Create table from language file

  result = initTable[string, string]()
  #var inputString: TaintedString

  if langAll.len() != 0:
    for line in langAll.splitLines:
      if line.len < 1 and line.substr(0, 0) != "[": continue
      var chunks = split(line, " = ")
      if chunks.len != 2:
        continue
      result[chunks[0]] = chunks[1]

  # Load elements from config.cfg
  result["Title"] = dict.getSectionValue("Person","title")
  result["AdminEmail"] = dict.getSectionValue("Person","AdminEmail")
  result["HelpEmail_EN"] = dict.getSectionValue("Person","HelpEmail_EN")
  result["HelpEmail_DK"] = dict.getSectionValue("Person","HelpEmail_DK")
  result["SupportEmail_EN"] = dict.getSectionValue("Person","SupportEmail_EN")
  result["SupportEmail_DK"] = dict.getSectionValue("Person","SupportEmail_DK")

  if result.len < 1: quit("Language file was empty!")


## Table containing the language file
let langTable = langTableInit()


proc langGen*(identifier, userLang = "EN"): string =
  ## Retrive language item based on user data
  ## echo langGen("HelpEmail", c.lang), e.g. langGen("HelpEmail", "c", "EN")

  if identifier in ["Title", "AdminEmail"]:
    return langTable[identifier]

  var lang = userLang
  if lang == "":
    lang = standardLanguage

  try:
    return langTable[identifier & "_" & lang]
  except:
    dbg("WARNING", "Error while retrieving language item: " & identifier & "_" & lang)
    return ""


proc langGenHost*(identifier, host: string): string =
  ## Retrive language item based host

  if host == "cxmanager.live":
    return langGen(identifier, "EN")
  elif host == "cxmanager.dk":
    return langGen(identifier, "DK")
  else:
    return langGen(identifier, "EN")