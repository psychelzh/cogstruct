list(
  tar_target(query_tmpl_data, fs::path("sql", "data.tmpl.sql"), format = "file"),
  tar_target(key, ".id"),
  targets_data,
  tarchetypes::tar_combine(data, targets_data[[1]]),
  tarchetypes::tar_combine(
    indices, 
    targets_data[[3]],
    command = combine_dm(!!!.x)
  ),
  tarchetypes::tar_combine(
    device_info,
    targets_data[[4]],
    command = combine_dm(!!!.x)
  ),
  tarchetypes::tar_combine(
    data_validation,
    targets_data[[5]],
    command = combine_dm(!!!.x)
  )
)
