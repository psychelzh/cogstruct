check_device <- function(dm) {
  key <- dm::dm_get_all_pks(dm, "meta") |> pluck("pk_col", 1)
  if (!has_name(dm::pull_tbl(dm, "data"), "device")) {
    dm <- dm |> 
      dm::dm_zoom_to("data") |> 
      dm::mutate(device = "mouse") |> 
      dm::dm_update_zoomed()
  }
  dm |> 
    dm::dm_zoom_to("data") |> 
    dm::group_by(across(all_of(key))) |> 
    dm::summarise(
      used_mouse = str_c(device, collapse = "-") |> 
        str_split("-") |> 
        map_lgl(~ any(.x == "mouse")), 
      .groups = "drop"
    ) |> 
    dm::dm_insert_zoomed("device_test") |> 
    dm::dm_select_tbl(-"data")
}
validate_data <- function(dm, name) {
  key <- dm::dm_get_all_pks(dm, "meta") |> pluck("pk_col", 1)
  if (name == "LdnTwr") {
    out <- dm |> 
      dm::dm_zoom_to("data") |> 
      dm::group_by(across(all_of(key))) |> 
      dm::summarise(valid_version = !anyNA(minmove), .groups = "drop") |> 
      dm::dm_insert_zoomed("validation")
  } else if (
    name %in% c("Grid2back", "Paint2back", "Digit3back", "Verbal3back")
  ) {
    out <- dm |> 
      dm::dm_zoom_to("data") |> 
      dm::group_by(across(all_of(key))) |> 
      dm::summarise(valid_version = any(type == "lure"), .groups = "drop") |> 
      dm::dm_insert_zoomed("validation")
  } else {
    out <- dm |> 
      dm::dm_zoom_to("data") |> 
      dm::group_by(across(all_of(key))) |> 
      dm::summarise(valid_version = TRUE, .groups = "drop") |> 
      dm::dm_insert_zoomed("validation")
  }
  out |> 
    dm::dm_select_tbl(-data)
}
combine_dm <- function(...) {
  list(...) |> 
    map(dm::dm_squash_to_tbl, start = "meta") |> 
    bind_rows(.id = "source") |> 
    extract(source, "game_name_abbr", "(?<=_)([^_]+$)")
}
clean_indices <- function(indices, file_keyboard, data_validation, device_info) {
  tests_keyboard <- read_lines(file_keyboard)
  validation <- device_info |> 
    mutate(valid_device = !(game_name %in% tests_keyboard & used_mouse)) |> 
    inner_join(data_validation) |> 
    filter(valid_device & valid_version) |> 
    group_by(user_id, game_name) |> 
    filter(
      if_else(
        str_detect(game_name_abbr, "[A|B]$"), 
        row_number(desc(game_time)) == 1,
        row_number(desc(game_time)) <= 2
      )
    ) |> 
    ungroup()
  indices |> 
    semi_join(validation) |> 
    mutate(across(starts_with("game_name"), ~ str_remove(.x, "[A|B]$"))) |> 
    group_by(user_id, game_name_abbr, game_name, index_name) |> 
    mutate(occasion = recode(row_number(game_time), `1` = "test", `2` = "retest")) |> 
    ungroup() |> 
    pivot_wider(
      id_cols = c(user_id, game_name, game_name_abbr, index_name), 
      names_from = occasion,
      values_from = score
    )
}
