# Copyright 2018 - Thomas T. Jarløv

router sysCompany:

  get "/adminsys/company/all":
    createTFD()
    if c.loggedIn and c.rank == AdminSys:
      resp genMain(c, genCompanyAll(c), "All companies")

  get "/adminsys/company/dodelete/@companyID":
    createTFD()
    if c.loggedIn and c.rank == AdminSys:
      execSafe(db, sqlDelete("company", ["id"]), @"companyID")
      redirect("/adminsys/company/all")

  get "/adminsys/company/add":
    createTFD()
    if c.loggedIn and c.rank == AdminSys:
      resp genMain(c, genCompanyAdd(c), "Add companies")

  post "/adminsys/company/doadd":
    createTFD()
    if c.loggedIn and c.rank == AdminSys:
      execSafe(db, sqlInsert("company", ["name"]), @"name")
      redirect("/adminsys/company/all")

  get "/adminsys/company/edit/@companyID":
    createTFD()
    if c.loggedIn and c.rank == AdminSys:
      resp genMain(c, genCompanyEdit(c, @"companyID"), "All companies")

  post "/adminsys/company/doedit/@companyID":
    createTFD()
    if c.loggedIn and c.rank == AdminSys:
      execSafe(db, sqlUpdate("company", ["name"], ["id"]), @"name", @"companyID")
      redirect("/adminsys/company/all")