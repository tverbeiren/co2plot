options(tidyverse.quiet = TRUE)
library(tidyverse)
library(lubridate, warn.conflicts = FALSE)
library(patchwork, warn.conflicts = FALSE)

day <- dmy(par$day)
who <- par$who

data <-
  list.files(path = par$input, pattern = "*.csv", full.names = TRUE) %>%
  map_df(read_csv, skip = 1, col_types = cols(time = "c", .default = "d"), col_names = c("time", "co2", "temperature", "humidity", "pressure"))

selection <- data %>%
  mutate(time = dmy_hms(time)) %>%
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
    axis.ticks.x = element_blank(),
    axis.title.x = element_blank()
  )

hum_plot <-
  ggplot(selection, aes(x = time)) +
  geom_line(aes(y = humidity)) +
  scale_x_datetime(breaks = "2 hour", date_labels = "%R") +
  labs(y = "Humidity (%)") +
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

if (par$add_temperature && par$add_humidity) {
  joined <- wrap_plots(co2_plot, hum_plot, temp_plot, ncol = 1, heights = c(4, 1, 1))
} else {
  if (par$add_temperature ) {
    joined <- wrap_plots(co2_plot, temp_plot, ncol = 1, heights = c(3, 1, 1))
  } else if (par$add_humidity ) {
    joined <- wrap_plots(co2_plot, hum_plot, ncol = 1, heights = c(3, 1, 1))
  } else {
    joined <- wrap_plots(co2_plot, ncol = 1, heights = c(4, 1, 1))
  }
}

output_file <- paste0(par$output, who, "-", day, ".", par$format)
ggsave(output_file, joined, height = 8, width = 8)

