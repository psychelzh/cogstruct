list(
  tar_target(file_config, "config.yml", format = "file"),
  tar_target(config_where, config::get("where", file = file_config))
)
