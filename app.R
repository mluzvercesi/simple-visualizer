library(plotly)
library(DT)
library(shinydashboard)

options(shiny.maxRequestSize = 10 * 1024^2) # change the maximum file size permitted

ui <- dashboardPage(
  dashboardHeader(disable = TRUE),
  dashboardSidebar(disable = TRUE),
  dashboardBody(
    tabsetPanel(
      # File settings and data filters
      tabPanel("Settings",
        div(h4("Upload a table to view file summary, data preview, and to select variables to work with")),
        # File settings
        fluidRow(
          column(4,
            box(title = "File input", width=12, status = "primary",
                fileInput("upload", NULL,
				          accept=c(".txt",".text",".csv",".tsv",".xls",".xlsx"),
				          placeholder="Select file to begin"))),
          column(8,
            valueBoxOutput("filename", width=4),
            valueBoxOutput("filesize", width=4),
            valueBoxOutput("filetype", width=4)),
        ),
        # Data filters
        fluidRow(
          column(4,
            box(title = "Data settings", width=12, status="success",
                selectInput("delimiter", "Delimiter",
                            c("Detect from file type" = "best",
                              Comma = ",", Colon = ":", Semicolon = ";", Tab = "\t", Space=" ", Pipe = "|")),
                checkboxInput("headerbool", "Set first row as header", value = TRUE),
                #checkboxInput("transpose", "Transpose", value = FALSE)
                selectInput("cols", "Keep columns", choices=NULL, multiple=TRUE)
                )),
          column(8, 
            box(title = "Data preview", width=12, status="warning",
                tableOutput("preview"))
          )
        )
      ),
      
      # Data exploration
      tabPanel("Explorer",
        div(h4("View filtered variables of full dataset, and some basic plots")),
        fluidRow(
          column(8,
            box(title = "Filtered dataset", width=12, status="warning",
                DT::dataTableOutput("filtered"))),
          column(4, #align='center',
            box(title = "Plot options", width=12, status="success",
                selectInput("plotType", "Plot Type",
                                     c(Scatter = "scatter", Histogram = "hist", Boxplot = "box")),
                conditionalPanel(
                  condition = "input.plotType == 'scatter'",
                  selectizeInput("scattervars", "Scatter variables (numeric)", choices=NULL, options=list(maxItems=2)),
                  selectizeInput("scattercol", "Color by (character)", choices="None", options=list(maxItems=1))
                ),
                conditionalPanel(
                  condition = "input.plotType == 'hist' || input.plotType == 'box'",
                  selectizeInput("singlevar", "Variable (numeric)", choices=NULL, options=list(maxItems=1))
                ),
                conditionalPanel(
                  condition = "input.plotType == 'hist'",
                  checkboxInput("histcustom", "Custom binning", value = FALSE),
                  conditionalPanel(
                    condition = "input.histcustom",
                    sliderInput("bins", "Number of bins", min = 1, max = 50, value = 10)
                  )
                ),
                conditionalPanel(
                  condition = "input.plotType == 'box'",
                  selectizeInput("boxcol", "Color by (character)", choices="None", options=list(maxItems=1))
                ),
                plotlyOutput("plot")
            )
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Update UI options ####
  observe({ # Update column names input
    req(data())
    updateSelectInput(session, "cols",
                      choices = names(data()),
                      selected = names(data()))
  })
  
  observe({ # Update scatter variables
    req(filteredData())
    
    varOptions <- names(which(sapply(filteredData(), is.numeric)))
    colOptions <- names(which(sapply(filteredData(), is.character)))
    
    if(length(varOptions)>0){
      updateSelectizeInput(session, "scattervars",
                      choices = varOptions,
                      selected = varOptions[c(1,2)])
      
      updateSelectizeInput(session, "singlevar",
                           choices = varOptions,
                           selected = varOptions[1])
    }
    
    if(length(colOptions)>0){
      updateSelectizeInput(session, "scattercol",
                           choices = c("None", colOptions),
                           selected = "None")
      
      updateSelectizeInput(session, "boxcol",
                           choices = c("None", colOptions),
                           selected = "None")
    }
  })
  
  # Reactives ####
  # File summary
  filesummary <- reactive({
    req(input$upload)
    summary <- input$upload[1:3]
    
    # transform Size to proper unit
    size <- summary[2]
    counter <- 1
    while(size>1024){
      size <- size/1024
      counter <- counter+1
    }
    colnames(summary)[2] <- c("B","kB", "MB", "GB")[counter]
    summary[2] <- size
    
    summary
  })
  
  # Full dataset
  data <- reactive({
    req(input$upload)
    
    filext <- tools::file_ext(input$upload$name)
    if(filext %in% c("txt","text","csv")){
      sepct <- ","
    } else if(filext %in% c("xls","xlsx","tsv")){
      sepct <- "\t"
    }
    if(!input$delimiter=="best"){
      # try to use custom delimiter 
      data <- tryCatch(read.table(file = input$upload$datapath, sep = input$delimiter,
                                  header=input$headerbool, fill=TRUE, quote="\""),
                       # otherwise use comma or tab
                        error = function(msg){
                          read.table(file = input$upload$datapath, sep = sepct,
                                     header=input$headerbool, fill=TRUE, quote="\"")})
    }else{
      data <- read.table(file = input$upload$datapath, sep = sepct, header=input$headerbool, fill=TRUE, quote="\"")
    }
    
    #if(input$transpose) t(data) else data # would this be useful at any point?
    data
  })
  
  # Filtered dataset
  filteredData <- reactive({
    if(any(!input$cols %in% colnames(data())) | is.null(input$cols)){
      data()
    }else{
      data()[,input$cols]
    }
  })
  
  # Outputs ####
  # Value boxes
  output$filename <- renderValueBox({
    valueBox(filesummary()[1], "File name",
             icon = icon("file"), color = "light-blue")
  })
  
  output$filesize <- renderValueBox({
    valueBox(paste(round(filesummary()[2], digits = 2), colnames(filesummary())[2]), "File size",
             icon = icon("file-zipper"), color = "aqua")
  })
  
  output$filetype <- renderValueBox({
    valueBox(filesummary()[3], "File type",
             icon = icon("file-circle-question"), color = "teal")
  })
  
  # data preview
	output$preview <- renderTable(head(filteredData()))
	
	# filtered data
	output$filtered <- DT::renderDataTable(filteredData(), options = list(scrollX = TRUE))
	
	# plots
	output$plot <- renderPlotly({
	  req(filteredData())
	  
	  if (input$plotType == "scatter") {
	    # Scatter plot
	    req(length(input$scattervars)==2)
	    
	    plot_ly(data = filteredData(), 
	          x = ~get(input$scattervars[1]), 
	          y = ~get(input$scattervars[2]), 
	          mode = "markers",
	          type = "scatter",
	          color = if(input$scattercol=="None") NULL else ~get(input$scattercol)) %>% 
	       layout(xaxis = list(title = as.character(input$scattervars[1])),
	              yaxis = list(title = as.character(input$scattervars[2])))
	    
	  } else if (input$plotType == "hist"){
	    # Histogram plot
	    minx <- floor(min(filteredData()[,input$singlevar]))
	    maxx <- ceiling(max(filteredData()[,input$singlevar]))
	    if(input$histcustom){
	      plot_ly(x = ~filteredData()[,input$singlevar], 
	              type = "histogram",
	              xbins = list(start = minx, end = maxx, size = (maxx-minx)/input$bins)) %>% 
	        layout(xaxis = list(title = as.character(input$singlevar)))
	    }else{
	      plot_ly(x = ~filteredData()[,input$singlevar], 
	            type = "histogram") %>% 
	      layout(xaxis = list(title = as.character(input$singlevar)))
	    }
	  } else if (input$plotType == "box"){
	    # Box plot
	    plot_ly(filteredData(), y = ~get(input$singlevar),
	            color = if(input$boxcol=="None") NULL else ~get(input$boxcol),
	            type = "box") %>% 
	      layout(yaxis = list(title = as.character(input$singlevar)))
	  }
	})
	
	session$onSessionEnded(function() {
	  stopApp()
	})
}

shinyApp(ui, server)
