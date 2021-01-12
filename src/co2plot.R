suppressPackageStartupMessages({
  library("lubridate")
  library("tidyverse")

  library("devtools")
  library("patchwork")
})

input_file <- par$input
day_str <- par$day
who <- par$who

day <- dmy(day_str)
wday <- wday(day)

start_am <- day + hms("00:00:01")
end_pm <- day + hms("23:59:99")

suppressMessages(
  data <-
    list.files(path = par$input, pattern = "*.csv", full.names = T) %>% 
    map_df(~read_csv(.))
)

colnames(data) <- c("time", "co2", "temperature", "humidity", "pressure")

data1 <- data %>%
  mutate(time = mdy_hms(time)) %>%
  distinct()

selection <- data1 %>%
  filter(between(time, start_am, end_pm))

co2_plot <- selection %>% ggplot(aes(x = time)) + geom_line(aes(y=co2)) +
  scale_x_datetime(breaks = "2 hour", date_labels = "%R") +
  geom_hline(yintercept = 900, color = "orange", size=1.5, linetype="dotted") +
  geom_hline(yintercept = 1200, color = "red", size=1.5, linetype="dotted") +
  labs(y="CO2 (ppm)")

co2_plot <- co2_plot

temp_plot <- selection %>% ggplot(aes(x = time)) + geom_line(aes(y=temperature)) +
  scale_x_datetime(breaks = "2 hour", date_labels = "%R") +
  labs(y="Temperature (°C)")

suppressMessages(
  co2_plot <- co2_plot +
    ggtitle(paste(toupper(substring(who,1,1)), "-", stamp_date("Tue Jan 1, 1999")(day))) +
    theme(plot.title = element_text(hjust = 0.5))
)
joined <- wrap_plots(co2_plot, temp_plot, ncol = 1, heights=c(4,1))

ggsave(paste(par$output, who, "-", day, ".", par$format, sep=""), joined, height = 6, width = 8)

