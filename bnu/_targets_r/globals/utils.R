check_used_mouse <- function(raw_parsed, ...) {
  if (!has_name(raw_parsed, "device")) {
    return(TRUE)
  }
  raw_parsed$device |> 
    str_c(collapse = "-") |> 
    str_split("-") |> 
    map_lgl(~ any(.x == "mouse"))
}
check_version <- function(raw_parsed, name, ...) {
  if (name == "LdnTwr") {
    return(has_name(raw_parsed, "minmove"))
  } 
  if (name %in% c("Grid2back", "Paint2back", "Digit3back", "Verbal3back")) {
    return(any(raw_parsed$type == "lure"))
  }
  return(TRUE)
}
validate_raw_parsed <- function(data_parsed, predicate, out, name = NULL) {
  data_parsed |> 
    mutate(
      "{out}" := map_lgl(
        raw_parsed,
        predicate,
        name = name
      ),
      .keep = "unused"
    )
}
clean_indices <- function(indices, games_req_kb, data_version, data_mouse) {
  validation <- data_mouse |> 
    mutate(valid_device = !(game_name %in% games_req_kb & used_mouse)) |> 
    inner_join(data_version) |> 
    filter(valid_device & valid_version) |> 
    left_join(data.iquizoo::game_info, by = c("game_id", "game_name")) |> 
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
    right_join(validation) |> 
    unnest(indices) |> 
    group_by(user_id, game_name_abbr, game_name, index_name) |> 
    mutate(
      occasion = case_when(
        str_detect(game_name_abbr, "A$") ~ "test",
        str_detect(game_name_abbr, "B$") ~ "retest",
        row_number(game_time) == 1 ~ "test",
        TRUE ~ "retest"
      ) |> 
        factor(c("test", "retest"))
    ) |> 
    ungroup() |> 
    mutate(across(starts_with("game_name"), ~ str_remove(.x, "[A|B]$"))) |>
    pivot_wider(
      id_cols = c(user_id, game_name, game_name_abbr, game_version, index_name), 
      names_from = occasion,
      values_from = score
    )
}
