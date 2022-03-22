list(
  tar_target(query_tmpl_data, fs::path("sql", "data.tmpl.sql"), format = "file"),
  tar_target(file_keyboard, "config/require_keybord.txt", format = "file"),
  tar_target(games_req_kb, read_lines(file_keyboard)),
  targets_data,
  tarchetypes::tar_combine(data, targets_data[[1]]),
  tarchetypes::tar_combine(
    indices, 
    targets_data[[3]]
  ),
  tarchetypes::tar_combine(
    data_mouse,
    targets_data[[4]]
  ),
  tarchetypes::tar_combine(
    data_version,
    targets_data[[5]]
  ),
  tar_target(
    indices_clean, 
    clean_indices(indices, games_req_kb, data_version, data_mouse)
  )
)
