combine_dm <- function(...) {
  list(...) |> 
    map(dm::dm_squash_to_tbl, start = "meta") |> 
    bind_rows(.id = "source") |> 
    extract(source, "game_name_abbr", "(?<=_)([^_]+$)")
}
clean_indices <- function(indices) {
  indices |> 
    group_by(user_id, game_name_abbr, game_name, index_name) |> 
    filter(row_number(desc(game_time)) <= 2) |> 
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
      id_cols = c(user_id, game_name, game_name_abbr, index_name), 
      names_from = occasion,
      values_from = score
    )
}
