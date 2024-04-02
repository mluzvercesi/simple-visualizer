library(plotly)
library(DT)

ui <- navbarPage("Data", id="nav",
	tabPanel("Settings",
		sidebarLayout(
			sidebarPanel(
				fileInput("upload", NULL,
				          accept=c(".txt",".text",".csv",".tsv",".xls",".xlsx")),
				tableOutput("filesummary")
			),
			mainPanel("Main contents",
			          checkboxInput("headerbool", "Header", value = TRUE),
			          #checkboxInput("transpose", "Transpose", value = FALSE),
			          selectInput("cols", "Keep columns", choices=NULL, multiple=TRUE),
				tableOutput("table")
			)
		)
	),
	
	tabPanel("Explorer",
	         dataTableOutput("filtered")
	)
)

server <- function(input, output, session) {
  observe({ # Update column names input
    req(input$upload)
    updateSelectInput(session, "cols",
                      choices = colnames(data()),
                      selected = colnames(data()))
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
    if(any(!input$cols %in% colnames(data())) | is.null(input$cols)) data() else data()[,input$cols]
  })
  
	output$filesummary <- renderTable(filesummary(), width="100%")
	
	output$table <- renderTable(head(filteredData()))
	
	output$filtered <- renderDataTable(filteredData())
}

shinyApp(ui, server)
