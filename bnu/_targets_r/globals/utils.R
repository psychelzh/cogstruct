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
