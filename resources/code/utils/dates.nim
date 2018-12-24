# Copyright 2018 - Thomas T. Jarløv

import strutils, times, logging


import ../utils/lognim


const monthNames = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


proc currentDatetime*(formatting: string): string=
  ## Getting the current local time

  if formatting == "full":
    result = format(local(getTime()), "yyyy-MM-dd HH:mm:ss")
  elif formatting == "date":
    result = format(local(getTime()), "yyyy-MM-dd")
  elif formatting == "compact":
    result = format(local(getTime()), "yyyyMMdd")
  elif formatting == "year":
    result = format(local(getTime()), "yyyy")
  elif formatting == "month":
    result = format(local(getTime()), "MM")
  elif formatting == "day":
    result = format(local(getTime()), "dd")
  elif formatting == "time":
    result = format(local(getTime()), "HH:mm:ss")



proc getDaysInMonthU*(month, year: int): int=
  ## Gets the number of days in the month and year
  ##
  ## Examples:
  ##
  runnableExamples:
    doAssert getDaysInMonthU(02, 2018) == 28
    doAssert getDaysInMonthU(10, 2020) == 31

  if month notin {1..12}:
    warn("getDaysInMonthU() wrong format input")
  else:
    result = getDaysInMonth(Month(month), year)



proc dateEpoch*(date, format: string): int64 =
  ## Transform a date in user format to epoch
  ## Does not utilize timezone
  ##
  ## Examples:
  ##
  runnableExamples:
    doAssert dateEpoch("2018-02-18", "YYYY-MM-DD") == "1518908400"

  try:
    case format
    of "YYYYMMDD":
      return toUnix(toTime(parse(date, "yyyyMMdd")))
    of "YYYY-MM-DD":
      return toUnix(toTime(parse(date, "yyyy-MM-dd")))
    of "YYYY-MM-DD HH:mm":
      return toUnix(toTime(parse(date, "yyyy-MM-dd HH:mm")))
    of "DD-MM-YYYY":
      return toUnix(toTime(parse(date, "dd-MM-yyyy")))
    else:
      when defined(dev):
        warn("dateEpoch() wrong format input")
      return 0
  except:
    when defined(dev):
      warn("dateEpoch() failed")
    return 0



proc epochDate*(epochTime, format: string, timeZone = "0"): string =
  ## Transform epoch to user formatted date
  ##
  ## Examples:
  ##
  runnableExamples:
    doAssert epochDate("1522995050", "YYYY-MM-DD HH:mm", "2") == "2018-04-06 - 08:10"


  if epochTime == "":
    return ""

  try:
    case format
    of "YYYY":
      let toTime = $(utc(fromUnix(parseInt(epochTime))) + initTimeInterval(hours=parseInt(timeZone)))
      return toTime.substr(0, 3)

    of "YYYY MM DD":
      let toTime = $(utc(fromUnix(parseInt(epochTime))) + initTimeInterval(hours=parseInt(timeZone)))
      return toTime.substr(0, 3) & " " & toTime.substr(5, 6) & " " & toTime.substr(8, 9)

    of "YYYY-MM-DD":
      let toTime = $(utc(fromUnix(parseInt(epochTime))) + initTimeInterval(hours=parseInt(timeZone)))
      return toTime.substr(0, 9)

    of "YYYY-MM-DD HH:mm":
      let toTime = $(utc(fromUnix(parseInt(epochTime))) + initTimeInterval(hours=parseInt(timeZone)))
      return toTime.substr(0, 9) & " - " & toTime.substr(11, 15)

    of "DD MM YYYY":
      let toTime = $(utc(fromUnix(parseInt(epochTime))) + initTimeInterval(hours=parseInt(timeZone)))
      return toTime.substr(8, 9) & " " & toTime.substr(5, 6) & " " & toTime.substr(0, 3)

    of "DD MMM YYYY HH:mm":
      let toTime = $(utc(fromUnix(parseInt(epochTime))) + initTimeInterval(hours=parseInt(timeZone)))
      return toTime.substr(8, 9) & " " & monthNames[parseInt(toTime.substr(5, 6))] & " " & toTime.substr(0, 3) & " " & toTime.substr(11, 15)

    of "DD":
      let toTime = $(utc(fromUnix(parseInt(epochTime))) + initTimeInterval(hours=parseInt(timeZone)))
      return toTime.substr(8, 9)

    of "MMM DD":
      let toTime = $(utc(fromUnix(parseInt(epochTime))) + initTimeInterval(hours=parseInt(timeZone)))
      return monthNames[parseInt(toTime.substr(5, 6))] & " " & toTime.substr(8, 9)

    of "MMM":
      let toTime = $(utc(fromUnix(parseInt(epochTime))) + initTimeInterval(hours=parseInt(timeZone)))
      return monthNames[parseInt(toTime.substr(5, 6))]

    else:
      let toTime = $(utc(fromUnix(parseInt(epochTime))) + initTimeInterval(hours=parseInt(timeZone)))
      debug("epochDate() no input specified")
      return toTime.substr(0, 9)

  except:
    return ""