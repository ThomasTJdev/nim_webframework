# Copyright 2018 - Thomas T. Jarløv

router users:
  get "/login":
    createTFD()
    c.errorMsg = @"message"
    resp genMain(c, genFormLogin(c), "Log in")


  get "/logout/?":
    createTFD()
    logout(c)
    redirect("/")


  get "/register":
    createTFD()
    resp genMain(c, genFormRegister(c), "Register")


  template finishLogin() =
    setCookie("sid", c.userpass, daysForward(7))
    redirect("/")


  post "/dologin":
    createTFD()
    if login(c, @"email", replace(@"password", " ", "")):
      setCookie("sid", c.userpass, daysForward(7))
      if @"path" != "":
        redirect(@"path")
      else:
        redirect("/")
    else:
      let msg = "Error"
      redirect("/login?message=" & msg)

  #[
  post "/doregister":
    createTFD()

    # If registrations is open for users
    if openAdminRegistration:

      # Register user
  ]#


  get "/users/add":
    createTFD()
    if not c.loggedIn:
      resp genMain(c, genFormLogin(c, redirectPath=c.req.path), "Log in")
    elif c.rank in [AdminSys, Admin, Moderator]:
      resp genMain(c, genUserAdd(c), "Add user")
    else:
      redirect("/users")


  get "/users/edit/@userID":
    createTFD()
    if not c.loggedIn:
      resp genMain(c, genFormLogin(c, redirectPath=c.req.path), "Log in")

    if not isDigit(@"userID"):
      c.errorMsg = "User not found"
      resp genMain(c, genUsersAll(c), "All users")

    if @"userID" == c.userid:
      resp genMain(c, genUserEdit(c, c.userid), "Edit profile")

    elif c.rank notin [AdminSys, Admin, Moderator]:
      c.errorMsg = "You are not allowed to edit this user"
      resp genMain(c, genUsersAll(c), "All users")

    else:
      var userRank: string
      if c.rank == AdminSys:
        userRank = getValueSafe(db, sqlSelect("person_access", ["status"], [""], ["user_id =", "company_id ="], "", "", ""), @"userID", @"syscompany")
      else:
        userRank = getValueSafe(db, sqlSelect("person_access", ["status"], [""], ["user_id =", "company_id ="], "", "", ""), @"userID", c.companyid)

      if userRank.len() == 0 or (c.rank != AdminSys and userRank == "AdminSys"):
        c.errorMsg = "User not found"
        resp genMain(c, genUsersAll(c), "All users")

      elif c.rank == Moderator and userRank == "Admin":
        c.errorMsg = "You are not allowed to edit this user"
        resp genMain(c, genUsersAll(c), "All users")

      else:
        resp genMain(c, genUserEdit(c, @"userID", @"syscompany"), "Edit profile")


  post "/users/doedit/@userID":
    createTFD()
    if not c.loggedIn:
      resp genMain(c, genFormLogin(c, redirectPath=c.req.path), "Log in")

    if not isDigit(@"userID"):
      c.errorMsg = "User not found"
      resp genMain(c, genUsersAll(c), "All users")

    var userRank: string
    if c.rank == AdminSys:
      userRank = getValueSafe(db, sqlSelect("person_access", ["status"], [""], ["user_id =", "company_id ="], "", "", ""), @"userID", @"syscompany")
    else:
      userRank = getValueSafe(db, sqlSelect("person_access", ["status"], [""], ["user_id =", "company_id ="], "", "", ""), @"userID", c.companyid)

    if userRank.len() == 0 or (c.rank != AdminSys and userRank == "AdminSys"):
      c.errorMsg = "User not found"
      resp genMain(c, genUsersAll(c), "All users")

    elif c.rank in [AdminSys]:
      execSafe(db, sqlUpdate("person", ["name", "email", "company"], ["id"]), @"name", @"email", @"company", @"userID")
      execSafe(db, sqlUpdate("person_access", ["status"], ["user_id", "company_id"]), @"rank", @"userID", @"syscompany")
      resp genMain(c, genUsersAll(c), "Edit profile")

    elif (c.rank == Moderator and userRank == "Admin"):
      c.errorMsg = "You are not allowed to edit this user"
      resp genMain(c, genUsersAll(c), "All users")

    elif c.rank in [Admin, Moderator] or c.userid == @"userID":
      execSafe(db, sqlUpdate("person", ["name", "email", "company", "status"], ["id"]), @"name", @"email", @"company", @"rank", @"userID")
      execSafe(db, sqlUpdate("person_access", ["status"], ["user_id", "company_id"]), @"rank", @"userID", c.companyid)
      resp genMain(c, genUsersAll(c), "Edit profile")

    else:
      c.errorMsg = "Error"
      resp genMain(c, genUsersAll(c), "All users")


  get "/users/dodelete/@userID":
    createTFD()
    if not c.loggedIn:
      resp genMain(c, genFormLogin(c, redirectPath=c.req.path), "Log in")
    elif c.rank in [AdminSys, Admin, Moderator]:

      if not isDigit(@"userID"):
        c.errorMsg = "User not found"
        resp genMain(c, genUsersAll(c), "All users")

      var userRank: string
      if c.rank == AdminSys:
        userRank = getValueSafe(db, sqlSelect("person_access", ["status"], [""], ["user_id =", "company_id ="], "", "", ""), @"userid", @"syscompany")
      else:
        userRank = getValueSafe(db, sqlSelect("person_access", ["status"], [""], ["user_id =", "company_id ="], "", "", ""), @"userid", c.companyid)

      if userRank.len() == 0:
        c.errorMsg = "User not found"
        resp genMain(c, genUsersAll(c), "All user")

      if userRank == "Admin" and c.rank == Moderator:
        c.errorMsg = "You can not delete an Admin"
        resp genMain(c, genUsersAll(c), "All user")

      execSafe(db, sqlDelete("person_access", ["user_id", "company_id"]), @"userID", c.companyid)
      execSafe(db, sqlDelete("person", ["id"]), @"userID")
      resp genMain(c, genUsersAll(c), "All user")
    else:
      redirect("/users")



  post "/users/doadd":
    createTFD()
    if c.loggedIn and c.rank in [AdminSys, Admin, Moderator]:

      # Register user
      let (userRegistrationB, userRegistrationS, userRegistrationCompanyID) = await registerManual(db, c.req, c.rank, c.companyid, c.userid, c.username, @"name", @"email", @"company", @"rank", @"timezone", @"language", @"companyaccess")

      if userRegistrationB:
        redirect("/users")

      else:
        logging.error("Manual registration: Error, " & userRegistrationS & " - Email: " & @"email" & " - Name: " & @"name" & ". UncleUserID: " & $c.userid)
        resp genMain(c, genError(c, "<h5>" & userRegistrationS & "<br></h5>"), "Error")

    else:
      redirect("/users")


  # Reset user password
  get "/resetpassword":
    createTFD()
    resp genMain(c, genUserResetPassword(c), "Reset password")


  # Send request for resetting
  post "/doresetpassword":
    createTFD()

    let (userResetB, userResetS) = await resetUserPassword(db, c.req, @"email", @"g-recaptcha-response", c.req.ip)

    if userResetB:
      c.message = "We have send you an email. Please click on the link in the email to reset your password."
      resp genMain(c, genInfo(c, "Reset password"), "Confirm your email")

    else:
      discard setError(c, "resetpassword", userResetS)
      resp genMain(c, genUserResetPassword(c), "Reset password")


  # Parse reset password email
  get "/emailResetPassword":
    createTFD()
    cond(@"name" != "")
    cond(@"epoch" != "")
    cond(@"ident" != "")
    var epochResetPassword: BiggestInt = 0
    cond(parseBiggestInt(@"epoch", epochResetPassword) > 0)

    if verifyIdentHashReset(db, @"name", $epochResetPassword, @"ident"):
      resp genMain(c, genUserResetPasswordNew(c, @"name", @"epoch", @"ident"), "Reset password")

    else:
      c.errorMsg = "An error occurred."
      resp genMain(c, genFormLogin(c), "Log in")


  # set new password after reset request
  post "/doemailresetpassword":
    createTFD()
    cond(@"name" != "")
    cond(@"epoch" != "")
    cond(@"ident" != "")
    cond(@"password" != "")
    var epochepochResetPasswordNew: BiggestInt = 0
    cond(parseBiggestInt(@"epoch", epochepochResetPasswordNew) > 0)

    when not defined(dev):
      if not await checkReCaptcha(@"g-recaptcha-response", c.req.ip):
        resp genMain(c, "The captcha was not correct.", "Error")

    if verifyIdentHashReset(db, @"name", $epochepochResetPasswordNew, @"ident"):
      let userID = getValueSafe(db, sqlSelect("person", ["id"], [""], ["name ="], "", "", ""), @"name")

      let (res, msg) = newPasswordSet(db, userID, @"password", minPassLength)
      if res:
        c.message = "Password reset successfully!"
        resp genMain(c, genFormLogin(c), "Log in")

      else:
        c.errorMsg = msg
        resp genMain(c, genFormLogin(c), "Log in")

    else:
      c.errorMsg = "An error occurred. Please try again."
      resp genMain(c, genFormLogin(c), "Log in")


  # Parse activation email
  get "/activateEmail/?":
    createTFD()
    cond(@"id" != "")
    cond(@"name" != "")
    cond(@"epoch" != "")
    cond(@"ident" != "")
    var epoch: BiggestInt = 0
    cond(parseBiggestInt(@"epoch", epoch) > 0)
    var success = false

    # Start by verifying, that the user is not trying to activate an already activated account
    let userStatus = getValueSafe(db, sqlSelect("person", ["status"], [""], ["id =", "name ="], "", "", ""), @"id", @"name")
    if userStatus != "EmailUnconfirmed":
      resp genMain(c, genFormLogin(c, "", "Your account is already activated. Please login."), "Log in")

    let userID = getValueSafe(db, sqlSelect("person", ["id"], [""], ["id =", "name ="], "", "", ""), @"id", @"name")

    # getRow instead of multiple getValueSafe
    let secretUrl = getValueSafe(db, sqlSelect("person", ["secretUrl"], [""], ["id ="], "", "", ""), userID)
    let password = getValueSafe(db, sqlSelect("person", ["password"], [""], ["id ="], "", "", ""), userID)
    let salt = getValueSafe(db, sqlSelect("person", ["salt"], [""], ["id ="], "", "", ""), userID)
    let secretUrlParam = makeIdentHash(@"name", password, @"epoch", salt, @"manual", @"ident")

    if verifyIdentHashRegister(db, userID, @"name", password, $epoch, salt, @"manual", @"ident") and secretUrl == secretUrlParam:

      let ban = parseEnum[Rank](db.getValueSafe(sql"select status from person where name = ?", @"name"))

      if ban == EmailUnconfirmed and @"manual" in ["Admin", "Moderator", "User", "Viewer"]:
        let registrationStatus = getValueSafe(db, sqlSelect("person", ["registration_status"], [""], ["id ="], "", "", ""), userID)
        success = tryExecSafe(db, sqlUpdate("person", ["status"], ["id", "name"]), registrationStatus, userID, @"name")

    else:
      # If activation link fails
      c.errorMsg = "Account activation failed. Please try again or contact: " & supportEmail
      resp genMain(c, genFormLogin(c), "Log in")

    if success:
      execSafe(db, sqlUpdate("person", ["secretUrl", "registration_status"], ["id", "name"]), "", "", userID, @"name")

      c.message = "Your account is now activated"
      resp genMain(c, genFormLogin(c), "Log in")

    else:
      c.message = "Account activation failed. Please try again or contact: " & supportEmail
      resp genMain(c, genFormLogin(c), "Log in")


  get "/users":
    createTFD()
    if not c.loggedIn:
      resp genMain(c, genFormLogin(c, redirectPath=c.req.path), "Log in")

    resp genMain(c, genUsersAll(c), "All users")