# Nim Webframework

This library provides a quick webpage setup. The main purpose is to provide a website frame with administration of users.

# First run

## Step 1
Rename **config/config_default.cfg** to **config/config.cfg** and insert your details and compile:

```nim
nim c -d:ssl websiteframework.nim
```

## Step 2
You need to create a database, append the arg "**createdb**". The library is prepared for Postgres - if you prefer SQLite, replace the import of `db_postgres` with `db_sqlite`.

```nim
./websiteframework createdb
```

## Step 3
To create an Admin account, append the arg "**createadmin**". Type your details and login.

```nim
./websiteframework createadmin
```

## Step 4
Navigate to `127.0.0.1:5000/login` and login.

```nim
./websiteframework
```

# User administration

## Modules
The framework comes with the following user administration:
1. View all users
2. Add user
3. Edit user
4. Delete user
5. Reset password

## User roles
There are 4 main user roles, 2 alternative and 1 system administrator:
1. Admin
2. Moderator
3. User
4. Viewer
5. EmailUnconfirmed
6. Deactivated
7. AdminSys *(only for maintenance)*

# Company structure
The framework is prepared for multiple different companies using the simultaneously but compartmentalized. The is done with the table `person_access`. When a user get access to a company, a row is added to this table.

Therefore a user can have access to multiple companies using the same email address. If the user has access to more than 1 company, the user needs to choose the company to access on login.

If there's only going to be 1 company accessing the platform, you don't have to mind the above.


## Add and edit companies
It is only the `AdminSys` who can edit and see all companies.

Navigate to `/adminsys/company/all` to manage the companies.


# Personalize

## General

To add pages you have to add a template (tmpl/\*.tmpl) and define a route (routes/\*.nim).

Let's create a new About page.

### New route

Open `resources/routes/routes_general.nim` and insert:
```nim
  get "/about":
    createTFD()
    if not c.loggedIn:
      resp genMain(c, genFormLogin(c, redirectPath=c.req.path), "Log in")
    else:
      resp genAbout(c, "", "About")
```

### Create HTML

Add a new file: `resources/tmpl/about.tmpl` and insert:
```nim
#? stdtmpl | standard
#
#proc genAbout(c: var TData): string =
# result = ""
<h1>About me</h1>
<p>Hello world</p>
#end proc
```

### Config sidebar

Open `resources/tmpl/sidebar.tmpl` and insert a new link:
```HTML
<li>
  <a href="/about">About</a>
</li>
```

### Let's test it

```nim
nim c -r -d:ssl websiteframework.nim

#Navigate to `127.0.0.1:5000/about`
```

# Screenshot
![logo](/public/images/screenshots/screen1.png)
