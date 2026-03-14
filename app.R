library(shiny)
library(DT)
library(ggplot2)
library(countrycode)

beetle_df <- read.csv(
  file.path("data", "raw", "gbif-beetle.csv"),
  sep = "\t"
)

beetle_df$continent <- countrycode(
  beetle_df$countryCode,
  origin = "iso2c",
  destination = "continent"
)

YEAR_MIN <- min(beetle_df$year, na.rm = TRUE)
YEAR_MAX <- max(beetle_df$year, na.rm = TRUE)

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

server <- function(input, output, session) {
  filtered_df <- reactive({
    beetle_df[
      !is.na(beetle_df$year) &
        beetle_df$year >= input$year_range[1] &
        beetle_df$year <= input$year_range[2],
    ]
  })

  output$plot_timeseries <- renderPlot({
    counts <- aggregate(gbifID ~ year, data = filtered_df(), FUN = length)
    names(counts)[2] <- "count"

    ggplot(counts, aes(x = year, y = count)) +
      geom_line(color = "#2e7d32") +
      geom_point(color = "#2e7d32") +
      labs(title = "Observations Over Time", x = "Year", y = "Observations") +
      theme_minimal()
  })

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

  output$table <- renderDT({
    datatable(filtered_df(), options = list(pageLength = 25, scrollX = TRUE))
  })
}

shinyApp(ui, server)
