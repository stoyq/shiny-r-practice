library(shiny)
library(DT)

beetle_df <- read.csv(
  file.path("..", "data", "raw", "gbif-beetle.csv"),
  sep = "\t"
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
      DTOutput("table")
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

  output$table <- renderDT({
    datatable(filtered_df(), options = list(pageLength = 25, scrollX = TRUE))
  })
}

shinyApp(ui, server)
