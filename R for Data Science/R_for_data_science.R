library(tidyverse)
library(ggplot2)
library(plotly)

#Read in the gapminder_clean.csv data as a tibble using read_csv.

data <- read.csv('gapminder_clean.csv') %>%
  as_tibble()

colnames(data)[colnames(data) == "CO2.emissions..metric.tons.per.capita."] <- "co2_emissions"
colnames(data)[colnames(data) == "Population.density..people.per.sq..km.of.land.area."] <- "population_density"
colnames(data)[colnames(data) == "Imports.of.goods.and.services....of.GDP."] <- "imports"
colnames(data)[colnames(data) == "Energy.use..kg.of.oil.equivalent.per.capita."] <- "energy_use"
colnames(data)[colnames(data) == "Life.expectancy.at.birth..total..years."] <- "life_expectancy"

#Filter the data to include only rows where Year is 1962

data_on_62 <- data %>% 
  filter(Year==1962)

#Make a scatter plot comparing 'CO2 emissions (metric tons per capita)' and gdpPercap for the filtered data.

ggplot(data_on_62, aes(x=co2_emissions, y = gdpPercap)) +
  geom_point()+
  labs(x="CO2 emissions (metric tons per capita)",y="GDP per capita",
       title="GDP per capita variation according to CO2 emissions")
  
#Calculate the correlation of 'CO2 emissions (metric tons per capita)' and gdpPercap

cor_test_res <- cor.test(data_on_62$co2_emissions, data_on_62$gdpPercap)
cor_test_res

#In what year is the correlation between 'CO2 emissions (metric tons per capita)' and gdpPercap the strongest?

highestcor <- data %>%
  select(Country.Name,Year,gdpPercap,co2_emissions) %>%
  drop_na() %>%
  group_by(Year) %>% 
  summarize(cor = cor(co2_emissions, gdpPercap)) %>%
  top_n(1,cor)
highestcor

#Create an interactive scatter plot comparing 'CO2 emissions (metric tons per capita)' and gdpPercap, where the point size is determined by pop (population) and the color is determined by the continent

co2_gdp_scatterplot <- data_on_62 %>%
  select(Country.Name,Year,co2_emissions,continent,pop,gdpPercap) %>%
  drop_na() %>%
  ggplot(aes(x=co2_emissions, 
             y=gdpPercap,
             color=continent,
             size=pop)) + 
  geom_point(alpha=0.5) +
  labs(x="CO2 emissions (metric tons per capita)",y="GDP per capita",
       title="GDP per capita variation according to CO2 emissions",) +
  scale_color_discrete(name ="Continent") +
  scale_size('', range=c(1, 10))
ggplotly(co2_gdp_scatterplot)

#What is the relationship between continent and 'Energy use (kg of oil equivalent per capita)'?

energy_continent_anova <- aov(energy_use ~ continent, data = data)
summary(energy_continent_anova)

#Is there a significant difference between Europe and Asia with respect to 'Imports of goods and services (% of GDP)' in the years after 1990?

relevant_continents <- c("Europe","Asia")

data_as_eu_after_90 <- data %>% 
  select(Country.Name,Year,imports,continent) %>%
  filter(continent %in% relevant_continents, Year>1990)

europe_asia_imports_t_test <- t.test(data_as_eu_after_90$imports[data_as_eu_after_90$continent=='Europe'],data_as_eu_after_90$Imports.of.goods.and.services....of.GDP.[data_as_eu_after_90$continent=='Asia'])
europe_asia_imports_t_test

#What is the country (or countries) that has the highest 'Population density (people per sq. km of land area)' across all years?

years <- unique(data$Year)
countries = unique(data$Country.Name[!is.na(data$Country.Name)])

pop_density_ranking <- rep(0, times=length(countries))
names(pop_density_ranking) <- countries

for (x in years) {
  year_data <- data %>% 
    select(Country.Name,Year,population_density) %>%
    na.omit()  %>%
    filter(Year == x)
  year_data$population_density <- rank(year_data$population_density,na.last = TRUE)
  for (z in year_data$Country.Name) {
    pop_density_ranking[[z]] <- pop_density_ranking[[z]] + year_data$population_density[year_data$Country.Name==z]
  }
}

pop_density_ranking <- pop_density_ranking %>%
  sort(decreasing = TRUE) %>%
  replace(pop_density_ranking==0, NA)

pop_density_ranking

ggplot(data, aes(x = Year, y = log10(population_density), group = Country.Name, color = Country.Name, label = Country.Name)) +
  geom_line() +
  theme(legend.position = "none")+
  geom_text(data = subset(data, ((Year==2002 & population_density>780)|(Year==2002 & population_density<10))), 
    aes(label = Country.Name, color = Country.Name, hjust = 0, vjust = 1))+
  labs(y="Population density (log10(people/square km of land area))",x="Year",
    title="Population density variation according to year per country",)

#What country (or countries) has shown the greatest increase in 'Life expectancy at birth, total (years)' since 1962?

life_expectancy_diff <- rep(0, times=length(countries))
names(life_expectancy_diff) <- countries

for (z in countries) {
  country_life_exp <- data %>% 
    select(Country.Name,Year,life_expectancy) %>%
    filter(Country.Name==z)
  years <- unique(country_life_exp$Year)
  print(country_life_exp$life_expectancy[country_life_exp$Year==tail(years,1)])
  print(country_life_exp$life_expectancy[country_life_exp$Year==head(years,1)])
  life_expectancy_diff[z] <- country_life_exp$life_expectancy[country_life_exp$Year==tail(years,1)] - country_life_exp$life_expectancy[country_life_exp$Year==head(years,1)] 
}

life_expectancy_diff <- life_expectancy_diff %>%
  sort(decreasing = TRUE)

life_expectancy_diff