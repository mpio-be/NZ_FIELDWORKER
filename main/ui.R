dashboardPage(
preloader = list(html = waiter::spin_loaders(id = 16, color = "#01125f"), color = "#b8c7c5"),   
dark = FALSE,
title = paste( "FIELDWORKER", year(Sys.Date()) ),
help = NULL, 

header = dashboardHeader(
    title = dashboardBrand(
        title = paste( pagetitle, year(Sys.Date()) ),
        image = "ICO.png"
    )
),

sidebar = dashboardSidebar(disable = TRUE),
controlbar = dashboardControlbar(

  uiOutput("clock"),
  code("Hard drive:"),
  uiOutput("hdd_state")
  ),


body = dashboardBody(

  bs4Dash::tabBox(id = "main", width = 12, collapsible =FALSE,

  tabPanel(title = "News",
    hr(),
    includeMarkdown("./www/help/news.md")
  ),

  tabPanel(title = "GPS",
    uiOutput("open_gps"),
    hr(),
    includeMarkdown("./www/help/gps.md")
  ),

  tabPanel(title = "ENTER DATA",
    uiOutput("new_data"),
    hr(),
    includeMarkdown("./www/help/enter_data.md")
  ),

  tabPanel(title = "DATABASE",
    
    div(class ="btn-toolbar btn-group-lg", style = "gap: 5px;" , 
    uiOutput("open_db")
    ),
    hr(),
    includeMarkdown("./www/help/database.md")

  ),

  tabPanel(title = "VIEW DATA", 

    bs4Dash::tabsetPanel(
      id = "tabset",
      .list = lapply(getOption('dbtabs_view'), function(i) {
        tabPanel(
          title = paste0("[", i, "]"),
          active = FALSE,
          DT::DTOutput(outputId = paste0(i, "_show"))
        )
      }) 
    )
  ),

  tabPanel(title = "NEST MAP",

      bs4Dash::box(width = 12,maximizable = TRUE,

      shiny::tags$style(type = "text/css", "#nest_dynmap_show {height: calc(95vh - 1px) !important;}"),
      leafletOutput(outputId = "nest_dynmap_show")

    )


  ), 

  tabPanel(title = "NESTS OVERVIEW",

    DT::DTOutput(outputId = "nests_overview")


  )
  
  )

)

)