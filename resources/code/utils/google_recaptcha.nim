import recaptcha, parsecfg, asyncdispatch, os, logging

import ../utils/lognim


var
  useCaptcha*: bool
  captcha*: ReCaptcha


# Using config.ini
let dict = loadConfig(getAppDir() & "/config/config.cfg")

# Web settings
let recaptchaSecretKey = dict.getSectionValue("reCAPTCHA","Secretkey")
let recaptchaSiteKey = dict.getSectionValue("reCAPTCHA","Sitekey")


proc setupReCapthca*() =
  # Activate Google reCAPTCHA
  if len(recaptchaSecretKey) > 0 and len(recaptchaSiteKey) > 0:
    useCaptcha = true
    captcha = initReCaptcha(recaptchaSecretKey, recaptchaSiteKey)
    debug("Initialized reCAPTCHA")

  else:
    useCaptcha = false
    warn("setupReCapthca(): Failed to initialize reCAPTCHA")


proc checkReCaptcha*(antibot, userIP: string): Future[bool] {.async.} =
  if useCaptcha:
    var captchaValid: bool = false
    try:
      captchaValid = await captcha.verify(antibot, userIP)
    except:
      warn("Error checking captcha: " & getCurrentExceptionMsg())
      captchaValid = false

    if not captchaValid:
      #return setError(c, "g-recaptcha-response", "Answer to captcha incorrect!")
      return false

    else:
      return true

  else:
    return true