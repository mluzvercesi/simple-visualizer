library(plotly)

ui <- navbarPage("Data", id="nav",
	tabPanel("Settings",
		sidebarLayout(
			sidebarPanel("Sidebar",
				fileInput("upload", NULL)),
			mainPanel("Main contents",
				tableOutput("files")
			)
		)
	),
	
	tabPanel("Explorer",
	)
)

server <- function(input, output, session) {
	output$files <- renderTable(input$upload)
}

shinyApp(ui, server)
