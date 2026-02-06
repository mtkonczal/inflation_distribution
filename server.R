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

    # Build colored subtitle from series names using brewer palette colors
    series_names <- levels(data_combined()$name)
    palette_colors <- brewer.pal(max(3, length(series_names)), input$color_scale)
    colored_labels <- mapply(function(nm, col) {
      paste0("<span style='color:", col, ";font-weight:bold;'>", nm, "</span>")
    }, series_names, palette_colors[seq_along(series_names)])
    subtitle_html <- paste(colored_labels, collapse = " &nbsp; | &nbsp; ")

    p <- ggplot(data = data_combined()) +
      geom_density(aes(x = Pvalues, fill = name, color = name),
                   alpha = 0.5, linewidth = 2, kernel = tolower(input$kernel_list)) +
      scale_color_brewer(palette = input$color_scale) +
      scale_fill_brewer(palette = input$color_scale) +
      theme_minimal() +
      theme(
        legend.position = "none",
        plot.title = element_text(size = 30, face = "bold"),
        plot.title.position = "plot",
        plot.subtitle = element_markdown(size = 20),
        axis.title = element_text(size = 16),
        plot.caption = element_text(size = 16),
        axis.text = element_text(size = 12)
      ) +
      labs(
        x = "Percent Change",
        title = paste0(input$inflation_type, " Inflation Density Distribution"),
        subtitle = subtitle_html
      ) +
      scale_x_continuous(label = percent)

    caption_text <- "Mike Konczal"
    if (exclude_pct() > 0) {
      caption_text <- paste0(caption_text, "\nTop and bottom ", percent(exclude_pct()), " of distribution excluded.")
    }
    p <- p + labs(caption = caption_text)

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
