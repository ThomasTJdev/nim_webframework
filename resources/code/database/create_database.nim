# Copyright 2018 - Thomas T. Jarløv

import db_postgres

proc createDatabase*(db: DbConn) =
  db.exec(sql"""
    create table if not exists company(
      id SERIAL PRIMARY KEY,
      name VARCHAR(30) NOT NULL
    );
  """)


  db.exec(sql"""
    create table if not exists company_access(
      id SERIAL PRIMARY KEY,
      company_id INTEGER NOT NULL,
      max_users INTEGER,

      foreign key (company_id) references company(id) ON DELETE CASCADE
    );
  """)

  db.exec(sql"""
    create table if not exists person(
      id SERIAL PRIMARY KEY,
      name VARCHAR(30) NOT NULL,
      password VARCHAR(300) NOT NULL,
      email VARCHAR(254) UNIQUE NOT NULL,
      company_id INTEGER,
      company VARCHAR(200),
      language VARCHAR(10),
      creation bigint NOT NULL default (extract(epoch from now())),
      modified bigint NOT NULL default (extract(epoch from now())),
      salt text NOT NULL,
      status varchar(30) NOT NULL,
      timezone VARCHAR(10),
      secretUrl VARCHAR(250),
      registration_status VARCHAR(30),
      lastOnline bigint NOT NULL default (extract(epoch from now())),

      foreign key (company_id) references company(id) ON DELETE CASCADE
    );
  """)

  db.exec(sql"""
    create table if not exists person_access(
      id SERIAL PRIMARY KEY,
      company_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      status VARCHAR(30) NOT NULL,

      foreign key (company_id) references company(id) ON DELETE CASCADE,
      foreign key (user_id) references person(id) ON DELETE CASCADE
    );
  """)

  db.exec(sql"""
    create table if not exists session(
      id SERIAL PRIMARY KEY,
      ip inet NOT NULL,
      password varchar(62) NOT NULL,
      userid integer NOT NULL,
      lastModified bigint NOT NULL default (extract(epoch from now())),
      foreign key (userid) references person(id) ON DELETE CASCADE
    );
  """)