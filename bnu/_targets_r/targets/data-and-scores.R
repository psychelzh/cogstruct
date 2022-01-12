list(
  tar_target(query_tmpl_data, fs::path("sql", "data.tmpl.sql"), format = "file"),
  tar_target(key, ".id"),
  targets_data,
  tarchetypes::tar_combine(data, targets_data[[1]]),
  tarchetypes::tar_combine(
    device_info,
    targets_data[[3]],
    command = list(!!!.x) |> 
      map(dm::dm_squash_to_tbl, start = "meta") |> 
      bind_rows(.id = "source")
  )
)
