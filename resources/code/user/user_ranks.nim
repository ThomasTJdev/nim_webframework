# Copyright 2018 - Thomas T. Jarløv

type
  Rank* = enum ## serialized as 'status'
    Viewer           ## Only view
    User             ## Ordinary user
    Moderator        ## Moderator: can ban/moderate users
    Admin            ## Admin: can do everything
    Deactivated      ## Arcived user - not active
    EmailUnconfirmed ## member with unconfirmed email address
    AdminSys         ## System administrator

const ranks* = @["Viewer", "User", "Moderator", "Admin", "Deactivated", "EmailUnconfirmed"]