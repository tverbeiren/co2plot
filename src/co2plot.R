suppressPackageStartupMessages({
  library("lubridate")
  library("tidyverse")

  library("patchwork")
})

day <- dmy(par$day)
who <- par$who

data <-
  list.files(path = par$input, pattern = "*.csv", full.names = TRUE) %>%
  map_df(read_csv, skip = 1, col_types = cols(time = "c", .default = "d"), col_names = c("time", "co2", "temperature", "humidity", "pressure"))

selection <- data %>%
  mutate(time = mdy_hms(time)) %>%
  distinct() %>%
  filter(between(time, day + hms("00:00:01"), day + hms("23:59:99")))

co2_plot <-
  ggplot(selection, aes(x = time)) +
  geom_line(aes(y = co2)) +
  scale_x_datetime(breaks = "2 hour", date_labels = "%R") +
  geom_hline(yintercept = 900, color = "orange", size = 1.5, linetype = "dotted") +
  geom_hline(yintercept = 1200, color = "red", size = 1.5, linetype = "dotted") +
  labs(y = "CO2 (ppm)") +
  ggtitle(paste0(toupper(substring(who, 1, 1)), " - ", format(day, "%a %b %d, %Y"))) +
  theme_bw() +
  theme(
    plot.title = element_text(hjust = 0.5),
    axis.line.x = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.title.x = element_blank()
  )

temp_plot <-
  ggplot(selection, aes(x = time)) +
  geom_line(aes(y = temperature)) +
  scale_x_datetime(breaks = "2 hour", date_labels = "%R") +
  labs(y = "Temperature (°C)") +
  theme_bw()

joined <- wrap_plots(co2_plot, temp_plot, ncol = 1, heights = c(4, 1))

ggsave(paste0(par$output, who, "-", day, ".", par$format), joined, height = 6, width = 8)

