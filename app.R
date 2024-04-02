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
				tableOutput("table")
			)
		)
	),
	
	tabPanel("Explorer",
	)
)

server <- function(input, output, session) {
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
  
  data <- reactive({
    req(input$upload)
    
    filext <- tools::file_ext(input$upload$name)
    if(filext %in% c("txt","text","csv")){
      data <- read.table(file = input$upload$datapath, sep = ",", header=input$headerbool)
    } else if(filext %in% c("xls","xlsx","tsv")){
      data <- read.table(file = input$upload$datapath, sep = "\t", header=input$headerbool)
    } else {
      data <- NULL
      warning('Supported file formats are plain text, comma/tab separated values, and Excel formats')
    }
    data
  })
  
	output$filesummary <- renderTable(filesummary(), width="100%")
	output$table <- renderTable(head(data()))
}

shinyApp(ui, server)
