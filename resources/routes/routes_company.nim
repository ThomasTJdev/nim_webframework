# Copyright 2018 - Thomas T. Jarløv

router company:

  get "/company/change":
    createTFD()
    if not c.loggedIn:
      resp genMain(c, genFormLogin(c, redirectPath=c.req.path), "Log in")

    if not multipleCompanies:
      redirect("/")

    resp genMain(c, genCompanyChange(c), "Change company")


  post "/company/change/@userID":
    createTFD()
    if not c.loggedIn:
      redirect("/login")

    if not multipleCompanies:
      redirect("/login")

    if @"userID" != c.userid:
      c.errorMsg = "The user ID does not match"
      resp genMain(c, genCompanyChange(c), "Change company")

    let userData = getRowSafe(db, sqlSelect("person_access", ["status", "company_id"], [""], ["user_id =", "company_id ="], "", "", ""), c.userid, @"companyid")

    if userData.len() == 0:
      c.errorMsg = "You do not have access to this company"
      resp genMain(c, genCompanyChange(c), "Change company")


    execSafe(db, sqlUpdate("person", ["status", "company_id"], ["id"]), userData[0], userData[1], c.userid)

    redirect("/company/change")