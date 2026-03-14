# Japanese Beetle Tracker - Shiny for R
# Individual assignment

library(shiny)
library(DT)         # interactive data tables
library(ggplot2)    # plots
library(countrycode) # maps ISO country codes to continents

# Load the raw data (tab-separated)
beetle_df <- read.csv(
  file.path("data", "raw", "gbif-beetle.csv"),
  sep = "\t"
)

# get continent from the ISO2 country code column
# e.g. "US" -> "Americas", "DE" -> "Europe"
beetle_df$continent <- countrycode(
  beetle_df$countryCode,
  origin = "iso2c",
  destination = "continent"
)

# Year slider range
YEAR_MIN <- min(beetle_df$year, na.rm = TRUE)
YEAR_MAX <- max(beetle_df$year, na.rm = TRUE)

# --- UI ---
# Sidebar: year range filter
# Main panel (top): timeseries plot and continent pie chart
# Main panel (bottom): full filtered data table
ui <- fluidPage(
  titlePanel("Japanese Beetle Tracker"),
  sidebarLayout(
    sidebarPanel(
      sliderInput(
        inputId = "year_range",
        label = "Year Range",
        min = YEAR_MIN,
        max = YEAR_MAX,
        value = c(YEAR_MIN, YEAR_MAX),
        sep = ""
      )
    ),
    mainPanel(
      fluidRow(
        column(6, plotOutput("plot_timeseries")),
        column(6, plotOutput("plot_continent"))
      ),
      fluidRow(
        column(12, DTOutput("table"))
      )
    )
  )
)

# --- Server ---
server <- function(input, output, session) {
  # Reactive dataframe: filters rows to the selected year range
  # All outputs below depend on this, so they all update when the slider changes
  filtered_df <- reactive({
    beetle_df[
      !is.na(beetle_df$year) &
        beetle_df$year >= input$year_range[1] &
        beetle_df$year <= input$year_range[2],
    ]
  })

  # Line chart: number of observations per year
  output$plot_timeseries <- renderPlot({
    counts <- aggregate(gbifID ~ year, data = filtered_df(), FUN = length)
    names(counts)[2] <- "count"

    ggplot(counts, aes(x = year, y = count)) +
      geom_line(color = "#2e7d32") +
      geom_point(color = "#2e7d32") +
      labs(title = "Observations Over Time", x = "Year", y = "Observations") +
      theme_minimal()
  })

  # Pie chart: share of observations per continent
  output$plot_continent <- renderPlot({
    counts <- aggregate(gbifID ~ continent, data = filtered_df(), FUN = length)
    names(counts)[2] <- "count"
    counts <- counts[!is.na(counts$continent), ]

    ggplot(counts, aes(x = "", y = count, fill = continent)) +
      geom_bar(stat = "identity", width = 1) +
      coord_polar("y") +
      labs(title = "Observations by Continent", fill = "Continent") +
      theme_void()
  })

  # Interactive table: all columns from the filtered dataset
  output$table <- renderDT({
    datatable(filtered_df(), options = list(pageLength = 25, scrollX = TRUE))
  })
}

shinyApp(ui, server)
