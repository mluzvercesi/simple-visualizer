library(plotly)

ui <- navbarPage("Data", id="nav",
	tabPanel("Settings",
		sidebarLayout(
			sidebarPanel("Sidebar",
				fileInput("upload", NULL, multiple = TRUE,
				          accept=c(".txt",".text",".csv",".tsv",".xls",".xlsx"))
			),
			mainPanel("Main contents",
				tableOutput("files"),
				tableOutput("table")
			)
		)
	),
	
	tabPanel("Explorer",
	)
)

server <- function(input, output, session) {
  data <- reactive({
    req(input$upload)
    
    filext <- tools::file_ext(input$upload$name)
    if(filext %in% c("txt","text","csv")){
      data <- read.table(file = input$upload$datapath, sep = ",", header=TRUE)
    } else if(filext %in% c("xls","xlsx","tsv")){
      data <- read.table(file = input$upload$datapath, sep = "\t", header=TRUE)
    } else {
      data <- NULL
      warning('Supported file formats are plain text, comma/tab separated values, and Excel formats')
    }
    data
  })
	output$files <- renderTable(input$upload)
	output$table <- renderTable(head(data()))
}

shinyApp(ui, server)
