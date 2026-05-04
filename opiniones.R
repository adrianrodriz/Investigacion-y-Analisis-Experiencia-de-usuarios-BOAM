# Análisis de comentarios de mejora del BOAM
# Requisitos sugeridos:
# install.packages(c("readr", "dplyr", "tidyr", "ggplot2", "lubridate",
#                  "stringr", "wordcloud", "stopwords", "tibble"))

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(lubridate)
  library(stringr)
  library(wordcloud)
  library(stopwords)
  library(tibble)
})

# --- Configuración ---
csv_file <- "300760-0-satisfaccion-boletin-boam-csv.csv"
language_selected <- "es"

col_satisfaccion <- "7_Indique su grado de satisfacción general con el Boletín Oficial del Ayuntamiento de Madrid"
col_comentarios <- "8_Le agradecemos cualquier comentario que nos ayude a mejorar"

stop_words <- if (language_selected == "en") {
  stopwords::stopwords("en")
} else {
  stopwords::stopwords("es")
}

# --- Carga de datos ---
reviews_df <- read_delim(
  csv_file,
  delim = ";",
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

filtered_reviews_df <- reviews_df

# --- Fechas y agrupacion  mensual (grafico barras apiladas) ---
filtered_reviews_df <- filtered_reviews_df %>%
  mutate(
    start_date = dmy_hm(.data[["start_date"]]),
    YearMonth = floor_date(start_date, "month")
  )

grouped_long <- filtered_reviews_df %>%
  filter(!is.na(.data[[col_satisfaccion]])) %>%
  count(YearMonth, .data[[col_satisfaccion]], name = "n") %>%
  rename(satisfaccion = 2)

p_stacked <- ggplot(grouped_long, aes(x = YearMonth, y = n, fill = factor(satisfaccion))) +
  geom_col(position = "stack") +
  scale_fill_viridis_d(option = "viridis") +
  labs(
    title = "Tendencia evolucion de comentarios de mejora",
    x = "Fecha de la encuesta (Año y Mes)",
    y = "Numero de comentarios",
    fill = "Satisfacción"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(p_stacked)

# --- Sentimiento y texto ---
filtered_reviews_df <- filtered_reviews_df %>%
  mutate(
    !!col_satisfaccion := suppressWarnings(as.numeric(.data[[col_satisfaccion]])),
    Sentiment = if_else(.data[[col_satisfaccion]] >= 5, "Positive", "Negative")
  )

positive_reviews <- filtered_reviews_df %>%
  filter(Sentiment == "Positive", !is.na(.data[[col_comentarios]])) %>%
  pull(.data[[col_comentarios]])

negative_reviews <- filtered_reviews_df %>%
  filter(Sentiment == "Negative", !is.na(.data[[col_comentarios]])) %>%
  pull(.data[[col_comentarios]])

calculate_word_frequencies <- function(reviews, sw) {
  if (!length(reviews)) {
    return(structure(integer(0), names = character(0)))
  }
  words_vec <- unlist(lapply(reviews, function(r) {
    w <- as.character(str_split(str_to_lower(r), "\\s+", simplify = TRUE))
    w[nchar(w) > 0 & !w %in% sw]
  }), use.names = FALSE)
  if (!length(words_vec)) {
    return(structure(integer(0), names = character(0)))
  }
  t <- sort(table(words_vec), decreasing = TRUE)
  setNames(as.integer(t), names(t))
}

positive_word_counts <- calculate_word_frequencies(positive_reviews, stop_words)
negative_word_counts <- calculate_word_frequencies(negative_reviews, stop_words)

all_words <- union(names(positive_word_counts), names(negative_word_counts))
get_cnt <- function(nm, vec) {
  v <- unname(vec[nm])
  ifelse(is.na(v), 0L, as.integer(v))
}

combined_word_dict <- setNames(
  get_cnt(all_words, positive_word_counts) + get_cnt(all_words, negative_word_counts),
  all_words
)
combined_word_dict <- sort(combined_word_dict[combined_word_dict > 0], decreasing = TRUE)

word_colors <- ifelse(
  get_cnt(names(combined_word_dict), positive_word_counts) >
    get_cnt(names(combined_word_dict), negative_word_counts),
  "green",
  "red"
)

set.seed(42)
wordcloud(
  words = names(combined_word_dict),
  freq = as.numeric(combined_word_dict),
  max.words = 200,
  colors = word_colors,
  ordered.colors = TRUE,
  scale = c(3.5, 0.35)
)

# --- Porcentajes y barras horizontales (top 25) ---
total_reviews <- nrow(filtered_reviews_df)

word_percentages <- tibble(word = all_words) %>%
  mutate(
    positive_percentage = vapply(
      word,
      function(w) get_cnt(w, positive_word_counts),
      numeric(1)
    ) / total_reviews * 100,
    negative_percentage = vapply(
      word,
      function(w) get_cnt(w, negative_word_counts),
      numeric(1)
    ) / total_reviews * 100
  ) %>%
  mutate(total_percentage = positive_percentage + negative_percentage) %>%
  slice_max(order_by = total_percentage, n = 25) %>%
  arrange(total_percentage)

top_words <- word_percentages

top_words_long <- top_words %>%
  pivot_longer(
    cols = c(negative_percentage, positive_percentage),
    names_to = "sentiment",
    values_to = "pct"
  ) %>%
  mutate(
    sentiment = recode(
      sentiment,
      negative_percentage = "Negative Sentiment",
      positive_percentage = "Positive Sentiment"
    ),
    word = factor(word, levels = top_words$word)
  )

p_bar <- ggplot(top_words_long, aes(x = pct, y = word, fill = sentiment)) +
  geom_col(position = position_dodge(width = 0.9)) +
  scale_fill_manual(values = c("Negative Sentiment" = "red", "Positive Sentiment" = "green")) +
  labs(
    title = "Top 25 Palabras mas frecuentes por sentimiento",
    x = "Porcentaje total de comentarios por palabra mencionada",
    y = "Palabras",
    fill = NULL
  ) +
  theme_minimal()

print(p_bar)
