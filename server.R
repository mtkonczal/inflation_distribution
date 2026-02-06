server <- function(input, output, session) {

  # Debounced slider to avoid jittery re-rendering while dragging
  exclude_pct <- debounce(reactive(input$exclude_percent), 500)

  # Reactive: filtered data for Series 1
  data1 <- reactive({
    req(input$date1, input$length1, input$inflation_type, exclude_pct())
    filter_inf_data(dataset, input$date1, input$length1,
                    input$inflation_type, exclude_pct(), 1 - exclude_pct())
  })

  # Reactive: filtered data for Series 2
  data2 <- reactive({
    if (!isTRUE(input$include2)) return(data.frame())
    req(input$date2, input$length2, input$inflation_type, exclude_pct())
    filter_inf_data(dataset, input$date2, input$length2,
                    input$inflation_type, exclude_pct(), 1 - exclude_pct())
  })

  # Combined data with dedup logic
  data_combined <- reactive({
    d1 <- data1()
    d2 <- data2()

    combined <- d1

    # Add Series 2 unless it duplicates Series 1
    if (nrow(d2) > 0 && !(input$date2 == input$date1 && input$length2 == input$length1)) {
      combined <- rbind(combined, d2)
    }

    combined$name <- factor(combined$name, levels = unique(combined$name))
    combined
  })

  output$plot <- renderPlot({
    req(nrow(data_combined()) > 0)

    p <- ggplot(data = data_combined()) +
      geom_density(aes(x = Pvalues, fill = name, color = name),
                   alpha = 0.5, linewidth = 2, kernel = tolower(input$kernel_list)) +
      scale_color_brewer(palette = input$color_scale) +
      scale_fill_brewer(palette = input$color_scale) +
      theme_minimal() +
      theme(
        legend.position = c(0.7, 0.8),
        plot.title = element_text(size = 30, face = "bold"),
        plot.title.position = "plot",
        plot.subtitle = element_text(size = 16),
        axis.title = element_text(size = 16),
        plot.caption = element_text(size = 16),
        axis.text = element_text(size = 12),
        legend.title = element_blank(),
        legend.text = element_text(size = 25)
      ) +
      labs(
        x = "Percent Change",
        title = paste0(input$inflation_type, " Inflation Density Distribution")
      ) +
      scale_x_continuous(label = percent)

    if (exclude_pct() > 0) {
      p <- p + labs(caption = paste0("Top and bottom ", percent(exclude_pct()), " of distribution excluded."))
    }

    p
  })

  # Update date selectors when inflation type changes
  observeEvent(input$inflation_type, {
    choices <- switch(input$inflation_type,
                      "PCE" = pce_dates,
                      "CPI" = cpi_dates)
    updateSelectInput(session, "date1", choices = choices, selected = input$date1)
    updateSelectInput(session, "date2", choices = choices, selected = input$date2)
  })
}
