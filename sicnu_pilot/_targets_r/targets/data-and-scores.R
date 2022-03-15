list(
  tar_target(query_tmpl_data, fs::path("sql", "data.tmpl.sql"), format = "file"),
  tar_target(key, ".id"),
  targets_data,
  tarchetypes::tar_combine(
    indices, 
    targets_data[[3]],
    command = combine_dm(!!!.x)
  ),
  tar_target(indices_clean, clean_indices(indices))
)
