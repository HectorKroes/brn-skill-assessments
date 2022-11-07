library(tidyverse)
library(ggplot2)
library(plotly)
library(countrycode)
library(kableExtra)
library(DT)
library(car)

# Read in the gapminder_clean.csv data as a tibble using read_csv.

data <- read.csv("gapminder_clean.csv") %>%
  as_tibble() %>%
  rename(co2_emissions = CO2.emissions..metric.tons.per.capita.) %>%
  rename(population_density = Population.density..people.per.sq..km.of.land.area.) %>%
  rename(imports = Imports.of.goods.and.services....of.GDP.) %>%
  rename(energy_use = Energy.use..kg.of.oil.equivalent.per.capita.) %>%
  rename(life_expectancy = Life.expectancy.at.birth..total..years.)

# Filter the data to include only rows where Year is 1962

data_on_62 <- data %>%
  filter(Year == 1962)

# Make a scatter plot comparing 'CO2 emissions (metric tons per capita)' and gdpPercap for the filtered data.

ggplot(data_on_62, aes(x = co2_emissions, y = gdpPercap)) +
  geom_point() +
  labs(
    x = "CO2 emissions (metric tons per capita)", y = "GDP per capita",
    title = "GDP per capita variation according to CO2 emissions"
  )

# Calculate the correlation of 'CO2 emissions (metric tons per capita)' and gdpPercap

cor_test_res <- cor.test(data_on_62$co2_emissions, data_on_62$gdpPercap)
cor_test_res

# In what year is the correlation between 'CO2 emissions (metric tons per capita)' and gdpPercap the strongest?

highest_cor <- data %>%
  select(Country.Name, Year, gdpPercap, co2_emissions) %>%
  drop_na() %>%
  group_by(Year) %>%
  summarize(cor = cor(co2_emissions, gdpPercap)) %>%
  top_n(1, cor)
highest_cor

# Create an interactive scatter plot comparing 'CO2 emissions (metric tons per capita)' and gdpPercap, where the point size is determined by pop (population) and the color is determined by the continent

co2_gdp_scatterplot <- data_on_62 %>%
  select(Country.Name, Year, co2_emissions, continent, pop, gdpPercap) %>%
  drop_na() %>%
  ggplot(aes(
    x = co2_emissions,
    y = gdpPercap,
    color = continent,
    size = pop
  )) +
  geom_point(alpha = 0.5) +
  labs(
    x = "CO2 emissions (metric tons per capita)", y = "GDP per capita",
    title = "GDP per capita variation according to CO2 emissions",
  ) +
  scale_color_discrete(name = "Continent") +
  scale_size("", range = c(1, 10))
ggplotly(co2_gdp_scatterplot)

# What is the relationship between continent and 'Energy use (kg of oil equivalent per capita)'?

leveneTest(energy_use ~ continent, data = data)

shapiro.test(data$energy_use)

kruskal.test(energy_use ~ continent, data = data)

# Is there a significant difference between Europe and Asia with respect to 'Imports of goods and services (% of GDP)' in the years after 1990?

relevant_continents <- c("Europe", "Asia")

data_as_eu_after_90 <- data %>%
  select(Country.Name, Year, imports, continent) %>%
  filter(continent %in% relevant_continents, Year > 1990)

shapiro.test(data_as_eu_after_90$imports[data_as_eu_after_90$continent == "Europe"])
shapiro.test(data_as_eu_after_90$imports[data_as_eu_after_90$continent == "Asia"])

# What is the country (or countries) that has the highest 'Population density (people per sq. km of land area)' across all years?

years <- unique(data$Year)
countries <- unique(data$Country.Name[!is.na(data$Country.Name)])

country_iterator <- function(country, year_data) {
  year_data <- year_data %>%
    filter(Country.Name == country)
  if (nrow(year_data) > 0) {
    return(year_data$population_density)
  } else {
    return(NA)
  }
}

year_round_calculus <- function(year) {
  year_data <- data %>%
    select(Country.Name, Year, population_density) %>%
    filter(Year == year)
  vector <- sapply(countries, country_iterator, year_data)
  vector <- rank(vector, na.last = "keep")
  return(vector)
}

valid_datapoints_calculator <- function(country) {
  country_data <- data %>%
    filter(Country.Name == country) %>%
    select(Country.Name, Year, population_density) %>%
    na.omit()
  valid_datapoints <- length(country_data$Year)
  return(valid_datapoints)
}

density_score <- rowSums(sapply(years, year_round_calculus))
valid_datapoints <- sapply(countries, valid_datapoints_calculator)

pop_density_ranking <- (density_score / valid_datapoints) %>%
  as_tibble() %>%
  mutate(country = countries) %>%
  filter(!is.infinite(value)) %>%
  arrange(desc(value))

max_dens <- pop_density_ranking %>%
  na.omit() %>%
  filter(value == max(value)) %>%
  pull(country)

data.frame(Country = pop_density_ranking$country, Score = pop_density_ranking$value) %>%
  datatable()

pd_country_codes <- countrycode(names(pop_density_ranking), origin = "country.name", destination = "iso3c")
pop_dens_df <- data.frame(country = names(pop_density_ranking), rank = unname(pop_density_ranking), code = pd_country_codes)

geo_config <- list(
  scope = "world",
  showocean = TRUE,
  oceancolor = toRGB("LightBlue"),
  showland = TRUE,
  landcolor = toRGB("#e5ecf6")
)

density_choropleth <- plot_ly(pop_dens_df, type = "choropleth", locations = pop_dens_df$code, z = pop_dens_df$rank, text = pop_dens_df$country, colors = "Reds") %>%
  layout(title = "Population density ranking dominance in the 1962-2007 period)", geo = geo_config) %>%
  colorbar(title = "Arbitrary units")

density_choropleth

g <- data.frame(names = factor(names(pop_density_ranking), levels = names(pop_density_ranking)), pop_density_ranking) %>%
  ggplot(aes(names, pop_density_ranking, color = names, fill = names)) +
  geom_col() +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 90)) +
  theme(legend.position = "none") +
  labs(
    y = "Population density ranking dominance in the 1962-2007 period (Arbitrary units)", x = "Country",
    title = "Most densily populated countries according to ranking dominance during 1962-2007 period"
  )

ggplotly(g)

ggplot(data, aes(x = Year, y = log10(population_density), group = Country.Name, color = Country.Name, label = Country.Name)) +
  geom_line() +
  theme(legend.position = "none") +
  geom_text(
    data = subset(data, ((Year == 2002 & population_density > 780) | (Year == 2002 & population_density < 10))),
    aes(label = Country.Name, color = Country.Name, hjust = 0, vjust = 1)
  ) +
  labs(
    y = "Population density (log10(people/square km of land area))", x = "Year",
    title = "Population density variation according to year per country",
  )

# What country (or countries) has shown the greatest increase in 'Life expectancy at birth, total (years)' since 1962?

life_expectancy_diff_calculator <- function(country, country_life_exp) {
  country_life_exp <- data %>%
    select(Country.Name, Year, life_expectancy) %>%
    filter(Country.Name == country)
  years <- unique(country_life_exp$Year)
  life_expectancy_years <- round(country_life_exp$life_expectancy[country_life_exp$Year == tail(years, 1)] - country_life_exp$life_expectancy[country_life_exp$Year == head(years, 1)], digits = 2)
  life_expectancy_pchange <- paste0(round(((country_life_exp$life_expectancy[country_life_exp$Year == tail(years, 1)] / country_life_exp$life_expectancy[country_life_exp$Year == head(years, 1)]) - 1) * 100, digits = 2), "%")
  return(c(life_expectancy_years, life_expectancy_pchange))
}

life_exp_df <- sapply(countries, life_expectancy_diff_calculator)

life_expectancy_diff <- as.data.frame(countries) %>%
  mutate(years = sapply(life_exp_df[1, ], as.integer)) %>%
  mutate(change = life_exp_df[2, ])

life_expectancy_diff %>%
  filter(!is.na(years)) %>%
  arrange(desc(years)) %>%
  datatable(colnames = c("Country", "Life expectancy change in years", "Percentage of growth in life expectancy"))

le_country_codes <- countrycode(as.vector(countries), origin = "country.name", destination = "iso3c")
life_expectancy_df <- data.frame(country = life_expectancy_diff$countries, years = life_expectancy_diff$years, code = le_country_codes)

geo_config <- list(
  scope = "world",
  showocean = TRUE,
  oceancolor = toRGB("LightBlue"),
  showland = TRUE,
  landcolor = toRGB("#e5ecf6")
)

le_choropleth <- plot_ly(life_expectancy_df, type = "choropleth", locations = life_expectancy_df$code, z = life_expectancy_df$years, text = life_expectancy_df$country, colors = "RdYlGn") %>%
  layout(title = "Changes in life expectancy in the 1962-2007 period)", geo = geo_config) %>%
  colorbar(title = "Years")

le_choropleth
