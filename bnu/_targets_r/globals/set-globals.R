future::plan(future.callr::callr)
games <- tarflow.iquizoo::search_games_mem(config::get("where"))
tar_option_set(
  package = c("tidyverse", "preproc.iquizoo", "tarflow.iquizoo"),
  format = "qs",
  imports = "preproc.iquizoo"
)
targets_data <- tarchetypes::tar_map(
  values = games,
  names = game_name_abbr,
  # major targets
  tar_target(data, pickup(query_tmpl_data, config_where_single_game)),
  tar_target(data_parsed, wrangle_data(data, key)),
  tar_target(
    indices,
    preproc_data(data_parsed, prep_fun, .input = input, .extra = extra)
  ),
  tar_target(device_info, check_device(data_parsed)),
  tar_target(data_validation, validate_data(data_parsed, game_name_abbr)),
  # configurations
  tar_target(
    config_where_single_game,
    insert_where_single_game(config_where, game_id)
  ),
  tar_target(
    input,
    config::get("input", config = game_name_abbr, file = file_config)
  ),
  tar_target(
    extra,
    config::get("extra", config = game_name_abbr, file = file_config)
  )
)
