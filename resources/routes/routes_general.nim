# Copyright 2018 - Thomas T. Jarløv

router general:

  get "/":
    createTFD()
    if not c.loggedIn:
      resp genFrontpage(c, "", title)
    else:
      resp genMain(c, "", "Welcome")
