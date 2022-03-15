list(
  tar_target(query_tmpl_users, fs::path("sql", "users.tmpl.sql"), format = "file"),
  tar_target(users, tarflow.iquizoo::pickup(query_tmpl_users, config_where))
)
