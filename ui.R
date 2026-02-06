page_fluid(
  title = "Inflation Density Distribution",

  h3("Inflation Density Distribution"),

  fluidRow(
    column(
      width = 12,
      card(
        full_screen = TRUE,
        withSpinner(plotOutput("plot", height = "600px"))
      )
    )
  ),

  fluidRow(
    # Series 1
    column(
      width = 3,
      h5("Series 1"),
      selectInput("date1", "Date:", cpi_dates, selected = maxdate),
      selectInput("length1", "Change Window:", levels(dataset$length_typeF), selected = "3-month")
    ),

    # Series 2
    column(
      width = 3,
      h5("Series 2"),
      conditionalPanel(
        condition = "input.include2",
        selectInput("date2", "Date:", cpi_dates, selected = maxdate_1yr),
        selectInput("length2", "Change Window:", levels(dataset$length_typeF), selected = "3-month")
      )
    ),

    # General settings
    column(
      width = 3,
      selectInput("inflation_type", "Inflation Type:", choices = c("CPI", "PCE"), selected = "CPI"),
      sliderInput("exclude_percent", "Exclude Top/Bottom Percent:",
                  min = 0, max = 0.5, value = 0.03, step = 0.01)
    ),

    # Show Series 2 checkbox + Advanced options + last updated
    column(
      width = 3,
      checkboxInput("include2", "Show Series 2", value = TRUE),
      accordion(
        open = FALSE,
        accordion_panel(
          "Advanced Options",
          selectInput("kernel_list", "Density Kernel:", choices = kernel_choices, selected = "Gaussian"),
          selectInput("color_scale", "Color Palette:", choices = brewer_colors, selected = "Set1")
        )
      ),
      br(),
      tags$small(tags$em(paste("Data last updated:", last_updated)))
    )
  )
)
