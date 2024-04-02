library(plotly)
library(DT)

ui <- navbarPage("Data", id="nav",
  # File ettings and filters
	tabPanel("Settings",
		sidebarLayout(
			sidebarPanel(
				fileInput("upload", NULL,
				          accept=c(".txt",".text",".csv",".tsv",".xls",".xlsx"),
				          placeholder="Select file to begin"),
				tableOutput("filesummary")
			),
			mainPanel(
			  fluidRow(
			    column(6, checkboxInput("headerbool", "Set first row as header", value = TRUE)),
			    #checkboxInput("transpose", "Transpose", value = FALSE)
			    column(6, selectInput("cols", "Keep columns", choices=NULL, multiple=TRUE))
			  ),
			  tableOutput("preview")
			)
		)
	),
	
  # Data exploration
	tabPanel("Explorer",
	   fluidRow(
	     column(8, DT::dataTableOutput("filtered")),
	     column(4,
	       fluidRow(
	         selectInput("plotType", "Plot Type",
	                     c(Scatter = "scatter", Histogram = "hist")
	         ),
	         conditionalPanel(
	           condition = "input.plotType == 'scatter'",
	           selectizeInput("scattervars", "Scatter variables", choices=NULL, options=list(maxItems=2)),
	           selectizeInput("scattercol", "Color by", choices="None", options=list(maxItems=1))
	         ),
	         conditionalPanel(
	           condition = "input.plotType == 'hist'",
	           selectizeInput("histvar", "Histogram variable", choices=NULL, options=list(maxItems=1))
	         )
	       ),
	       fluidRow(plotlyOutput("plot"))
	     )
	   )
	)
)

server <- function(input, output, session) {
  observe({ # Update column names input
    req(input$upload)
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
      
      updateSelectizeInput(session, "histvar",
                           choices = varOptions,
                           selected = varOptions[1])
    }
    
    if(length(colOptions)>0){
      updateSelectizeInput(session, "scattercol",
                           choices = c("None", colOptions),
                           selected = "None")
    }
  })
  
  filesummary <- reactive({
    req(input$upload)
    summary <- input$upload[1:3]
    colnames(summary) <- c("File name", "Size", "Type")
    
    # transform Size to proper unit
    size <- summary[2]
    counter <- 1
    while(size>1024){
      size <- size/1024
      counter <- counter+1
    }
    colnames(summary)[2] <- paste0("Size (",c("B","kB", "MB", "GB")[counter],")")
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
    data <- read.table(file = input$upload$datapath, sep = sepct, header=input$headerbool)
    #if(input$transpose) t(data) else data
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
  
  # Outputs
	output$filesummary <- renderTable(filesummary(), width="100%",
	                                  caption="File summary", caption.placement="top")
	
	output$preview <- renderTable(head(filteredData()), width="100%",
	                              caption="Dataset preview", caption.placement="top")
	
	output$filtered <- DT::renderDataTable(filteredData(), options = list(scrollX = TRUE))
	
	output$plot <- renderPlotly({
	  req(filteredData())
	  
	  # Scatter plot
	  if (input$plotType == "scatter") {
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
	    plot_ly(x = ~filteredData()[input$histvar], 
	            type = "histogram")
	  }
	})
}

shinyApp(ui, server)
