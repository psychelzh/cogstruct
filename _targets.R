library(targets)
future::plan(future.callr::callr)
tar_option_set(packages = "tidyverse")
list(
  tar_target(
    exclude_bnu,
    c("数字推理", "文字推理", "数字推理A", "数字推理B", "文字推理A", "文字推理B")
  ),
  tar_target(
    file_data_valid_bnu,
    "bnu/_targets/objects/data_valid",
    format = "file"
  ),
  tar_target(
    file_data_valid_sicnu,
    "sicnu/_targets/objects/data_valid",
    format = "file"
  ),
  tar_target(
    data_raw,
    bind_rows(
      bnu = qs::qread(file_data_valid_bnu),
      sicnu = qs::qread(file_data_valid_sicnu),
      .id = "source"
    ) |>
      group_by(game_name) |>
      filter(game_version == max(game_version)) |>
      ungroup()
  ),
  tar_target(
    file_indices_bnu,
    "bnu/_targets/objects/indices_clean",
    format = "file"
  ),
  tar_target(
    file_indices_sicnu,
    "sicnu/_targets/objects/indices_clean",
    format = "file"
  ),
  tar_target(
    indices_clean,
    bind_rows(
      bnu = qs::qread(file_indices_bnu),
      sicnu = qs::qread(file_indices_sicnu),
      .id = "source"
    ) |>
      filter(!(game_name %in% exclude_bnu & source == "bnu")) |>
      group_by(game_name) |>
      filter(game_version == max(game_version)) |>
      ungroup() |>
      filter(if_all(contains("test"), is.finite)) |>
      group_by(game_name, index_name) |>
      mutate(
        data.frame(test = test, retest = retest) |>
          performance::check_outliers(method = "mahalanobis") |>
          as_tibble()
      ) |>
      ungroup()
  ),
  tar_target(
    file_indices_even_bnu,
    "bnu/_targets/objects/indices_clean_even",
    format = "file"
  ),
  tar_target(
    file_indices_even_sicnu,
    "sicnu/_targets/objects/indices_clean_even",
    format = "file"
  ),
  tar_target(
    indices_even,
    bind_rows(
      bnu = qs::qread(file_indices_even_bnu),
      sicnu = qs::qread(file_indices_even_sicnu),
      .id = "source"
    ) |>
      group_by(game_name) |>
      filter(game_version == max(game_version)) |>
      ungroup()
  ),
  tar_target(
    file_indices_odd_bnu,
    "bnu/_targets/objects/indices_clean_odd",
    format = "file"
  ),
  tar_target(
    file_indices_odd_sicnu,
    "sicnu/_targets/objects/indices_clean_odd",
    format = "file"
  ),
  tar_target(
    indices_odd,
    bind_rows(
      bnu = qs::qread(file_indices_odd_bnu),
      sicnu = qs::qread(file_indices_odd_sicnu),
      .id = "source"
    ) |>
      group_by(game_name) |>
      filter(game_version == max(game_version)) |>
      ungroup()
  ),
  tarchetypes::tar_file_read(
    config_ic,
    "config/internal-consistency.csv",
    read_csv(!!.x, show_col_types = FALSE)
  ),
  tar_target(
    reliability_split_half,
    bind_rows(
      odd = indices_odd,
      even = indices_even,
      .id = "halves"
    ) |>
      semi_join(filter(config_ic, method == "prophecy"), by = "game_name") |>
      pivot_wider(
        id_cols = c(user_id, game_name, game_name_abbr, game_version, index_name),
        names_from = halves,
        values_from = test,
        names_prefix = "score_"
      ) |>
      group_by(game_name, game_name_abbr, game_version, index_name) |>
      summarise(
        n_split_half = sum(!is.na(score_odd) & !is.na(score_even)),
        r_split_half = cor(score_odd, score_even, use = "pairwise"),
        split_half = (2 * r_split_half) / (1 + r_split_half),
        .groups = "drop"
      ) |>
      drop_na() |>
      mutate(game_name_origin = game_name) |>
      mutate(
        across(
          c(game_name, game_name_abbr),
          ~ str_remove(., "[A|B]$")
        )
      )
  ),
  tar_target(
    reliability_alpha,
    data_raw |>
      semi_join(filter(config_ic, method == "alpha"), by = "game_name") |>
      # BNU source data were incorrect for these games
      filter(!(game_name %in% exclude_bnu & source == "bnu")) |>
      # data from the last time of each test is deemed the right one
      left_join(data.iquizoo::game_info, by = c("game_id", "game_name")) |>
      group_by(user_id, game_name, game_version) |>
      filter(row_number(desc(game_time)) == 1) |>
      ungroup() |>
      unnest(raw_parsed) |>
      filter(acc != -1) |>
      mutate(
        block = if_else(
          block == 1,
          "prac", "test", ""
        )
      ) |>
      group_by(user_id, game_id) |>
      mutate(item = row_number(itemid)) |>
      ungroup() |>
      group_by(game_name, game_name_abbr, game_version, block) |>
      group_modify(
        ~ .x |>
          pivot_wider(
            id_cols = user_id,
            names_from = item,
            values_from = acc
          ) |>
          select(-user_id) |>
          psych::alpha(warnings = FALSE) |>
          pluck("total", "std.alpha") |>
          as_tibble_col(column_name = "alpha")
      ) |>
      ungroup() |>
      mutate(game_name_origin = game_name) |>
      mutate(
        across(
          c(game_name, game_name_abbr),
          ~ str_remove(., "[A|B]$")
        )
      )
  ),
  tar_target(
    reliability_test_retest,
    indices_clean |>
      group_by(game_name, game_name_abbr, game_version, index_name) |>
      group_modify(
        ~ tibble(
          n_test_retest = nrow(.x),
          n_no_outlier = .x |>
            filter(!Outlier) |>
            nrow(),
          icc = .x |>
            select(contains("test")) |>
            psych::ICC() |>
            pluck("results", "ICC", 2),
          icc_no_outlier = .x |>
            filter(!Outlier) |>
            select(contains("test")) |>
            psych::ICC() |>
            pluck("results", "ICC", 2),
          r_test_retest = cor(.x$test, .x$retest),
          r_test_retest_no_outlier = with(
            subset(.x, !Outlier),
            cor(test, retest)
          )
        )
      ) |>
      ungroup()
  ),
  tar_target(
    reliability,
    reliability_test_retest |>
      full_join(
        bind_rows(reliability_split_half, reliability_alpha) |>
          mutate(index_name = coalesce(index_name, "nc")),
        by = c("game_name", "game_name_abbr", "game_version", "index_name")
      ) |>
      mutate(game_name_origin = coalesce(game_name_origin, game_name)) |>
      select(game_name_origin, everything())
  )
)
