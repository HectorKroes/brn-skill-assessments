library(tidyverse)
library(ggplot2)
library(plotly)

#Read in the gapminder_clean.csv data as a tibble using read_csv.

data <- read.csv('gapminder_clean.csv') %>%
  as_tibble()

#Filter the data to include only rows where Year is 1962

data_on_62 <- data %>% 
  filter(Year==1962)

#Make a scatter plot comparing 'CO2 emissions (metric tons per capita)' and gdpPercap for the filtered data.

ggplot(data_on_62, aes(x=CO2.emissions..metric.tons.per.capita., y = gdpPercap)) +
  geom_point()+
  labs(x="CO2 emissions (metric tons per capita)",y="GDP per capita",
       title="GDP per capita variation according to CO2 emissions")
  
#Calculate the correlation of 'CO2 emissions (metric tons per capita)' and gdpPercap

cor_test_res <- cor.test(data_on_62$CO2.emissions..metric.tons.per.capita., data_on_62$gdpPercap)
cor_test_res

#In what year is the correlation between 'CO2 emissions (metric tons per capita)' and gdpPercap the strongest?

highestcor <- data %>%
  select(Country.Name,Year,gdpPercap,CO2.emissions..metric.tons.per.capita.) %>%
  drop_na() %>%
  group_by(Year) %>% 
  summarize(cor = cor(CO2.emissions..metric.tons.per.capita., gdpPercap)) %>%
  top_n(1,cor)
highestcor

#Create an interactive scatter plot comparing 'CO2 emissions (metric tons per capita)' and gdpPercap, where the point size is determined by pop (population) and the color is determined by the continent

co2_gdp_scatterplot <- data_on_62 %>%
  select(Country.Name,Year,CO2.emissions..metric.tons.per.capita.,continent,pop,gdpPercap) %>%
  drop_na() %>%
  ggplot(aes(x=CO2.emissions..metric.tons.per.capita., 
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

energy_continent_anova <- aov(Energy.use..kg.of.oil.equivalent.per.capita. ~ continent, data = data)
summary(energy_continent_anova)

#Is there a significant difference between Europe and Asia with respect to 'Imports of goods and services (% of GDP)' in the years after 1990?

relevant_continents <- c("Europe","Asia")

data_as_eu_after_90 <- data %>% 
  select(Country.Name,Year,Imports.of.goods.and.services....of.GDP.,continent) %>%
  filter(continent %in% relevant_continents, Year>1990)

europe_asia_imports_t_test <- t.test(data_as_eu_after_90$Imports.of.goods.and.services....of.GDP.[data_as_eu_after_90$continent=='Europe'],data_as_eu_after_90$Imports.of.goods.and.services....of.GDP.[data_as_eu_after_90$continent=='Asia'])
europe_asia_imports_t_test

#What is the country (or countries) that has the highest 'Population density (people per sq. km of land area)' across all years?

years <- unique(data$Year)
countries = unique(data$Country.Name[!is.na(data$Country.Name)])

pop_density_ranking <- rep(0, times=length(countries))
names(pop_density_ranking) <- countries

for (x in years) {
  year_data <- data %>% 
    select(Country.Name,Year,Population.density..people.per.sq..km.of.land.area.) %>%
    na.omit()  %>%
    filter(Year == x)
  year_data$Population.density..people.per.sq..km.of.land.area. <- rank(year_data$Population.density..people.per.sq..km.of.land.area.,na.last = NA)
  rank(year_data$Population.density..people.per.sq..km.of.land.area.,na.last = FALSE)
  for (z in year_data$Country.Name) {
    pop_density_ranking[[z]] <- pop_density_ranking[[z]] + year_data$Population.density..people.per.sq..km.of.land.area.[year_data$Country.Name==z]
  }
}

pop_density_ranking <- pop_density_ranking %>%
  sort(decreasing = TRUE) %>%
  replace(pop_density_ranking==0, NA)

ggplot(data, aes(x = Year, y = log10(Population.density..people.per.sq..km.of.land.area.), group = Country.Name, color = Country.Name, label = Country.Name)) +
  geom_line() +
  theme(legend.position = "none")+
  geom_text(data = subset(data, ((Year==2002 & Population.density..people.per.sq..km.of.land.area.>780)|(Year==2002 & Population.density..people.per.sq..km.of.land.area.<10))), 
    aes(label = Country.Name, color = Country.Name, hjust = 0, vjust = 1))+
  labs(y="Population density (log10(people/square km of land area))",x="Year",
    title="Population density variation according to year per country",)

#What country (or countries) has shown the greatest increase in 'Life expectancy at birth, total (years)' since 1962?
