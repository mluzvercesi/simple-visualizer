from shiny import App, ui, reactive, render, req
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

app_ui = ui.page_fluid(
    ui.navset_tab(
        # File settings and data filters
        ui.nav_panel("Settings",
            ui.tags.h4("Upload a table to view file summary, data preview, and to select variables to work with"),
            # File settings
            ui.row(
                ui.column(4,
                    ui.card(ui.card_header("File input", {"style": "border-top: solid steelblue"}),
                        ui.input_file("upload", "File input",
                                      accept=[".txt",".text",".csv",".tsv",".xls",".xlsx"],
                                      placeholder='Select file to begin'))),
                ui.column(8,
                    ui.layout_column_wrap(
                    ui.value_box(
                        "File name",
                        value=ui.output_text("filename"),
                        theme="bg-gradient-blue-purple",
                    ),
                    ui.value_box(
                        "File size",
                        value=ui.output_text("filesize"),
                        theme="bg-gradient-cyan-purple",
                        showcase_layout="top right",
                    ),
                    ui.value_box(
                        "File type",
                        value=ui.output_text("filetype"),
                        theme="bg-gradient-teal-purple",
                        showcase_layout="bottom",
                    ))
                )
            ),
            # Data filters
            ui.row(
                ui.column(4,
                    ui.card(ui.card_header("Data settings", {"style": "border-top: solid green"}),
                        ui.input_checkbox("headerbool", "Set first row as header", value = True),
                        ui.input_selectize("cols", "Keep columns", [], multiple=True))),
                ui.column(8,
                    ui.card(ui.card_header("Data preview", {"style": "border-top: solid orange"}),
                            ui.output_table("preview")))
            )
        ),
        # Data explorer
        ui.nav_panel("Explorer",
            ui.tags.h4("View filtered variables of full dataset, and some basic plots"),
            ui.row(
                # Filtered dataset
                ui.column(8,
                    ui.card(ui.card_header("Filtered data", {"style": "border-top: solid orange"}),
                        ui.output_data_frame("filtered"))),
                # Plot options
                ui.column(4,
                    ui.card(ui.card_header("Plot options", {"style": "border-top: solid green"}),
                        ui.input_select("plotType", "Plot Type",
                                        {"scatter":"Scatter", "hist":"Histogram", "box":"Boxplot"}),
                        ui.panel_conditional("input.plotType == 'scatter'",
                            ui.input_selectize(id="scattervars", label="Scatter variables (numeric)", choices=[], options={"maxItems":2})),
                        ui.panel_conditional("input.plotType == 'hist' || input.plotType == 'box'",
                            ui.input_selectize(id="singlevar", label="Variable (numeric)", choices=[])),
                        ui.output_plot("plot")
                    )
                )
            )
        ),
    )
)


def server(input, output, session):
    '''Reactives and update inputs'''
    @reactive.effect
    def _():
        f = req(input.upload())
        ui.update_selectize("cols",choices=list(data().columns),selected=list(data().columns))
    
    @reactive.effect
    def _():
        if len(list(filteredData().columns))>0:
            varOptions = filteredData().select_dtypes(include="number").columns.tolist()
            ui.update_selectize("scattervars",choices=varOptions,selected=varOptions[0])
            ui.update_selectize("singlevar", choices=varOptions, selected=varOptions[0])
        else:
            ui.update_selectize("scattervars",choices=[])
            ui.update_selectize("singlevar", choices=[])

    @reactive.Calc()
    def data():
        f = req(input.upload())
        fext = Path(f[0]['name']).suffix
        sepct = ","
        if fext in ["xls","xlsx","tsv"]:
            sepct = "\t"
        
        if input.headerbool()==True:
            headerbool = 0
        else:
            headerbool = None

        return pd.read_csv(f[0]['datapath'], sep = sepct, header = headerbool, quotechar="\"")
    
    @reactive.Calc()
    def filteredData():
        if all(c in list(data().columns) for c in input.cols()):
            return data()[list(input.cols())]
        else:
            return data()
    
    '''Outputs'''
    # Value boxes
    @render.text
    def filename():
        f = req(input.upload())
        return f[0]["name"]
    
    @render.text
    def filesize():
        f = req(input.upload())
        size = int(f[0]["size"])
        counter=0
        while size>1024:
            size = size/1024
            counter+=1
        size = round(size, 2)
        return "{}{}".format(size,["B","kB", "MB", "GB"][counter])
    
    @render.text
    def filetype():
        f = req(input.upload())
        return f[0]["type"]
    
    # Table
    @render.table
    def preview():
        f = req(input.upload())
        return filteredData().head(6)
    
    @render.data_frame
    def filtered():
        return filteredData()
    
    # Plots
    @render.plot
    def plot():
        fig, ax = plt.subplots()
        if input.plotType()=="scatter":
            sv = req(input.scattervars())
            if len(sv)==1:
                ax.scatter(filteredData().index, filteredData()[list(input.scattervars())])
                plt.xlabel("Index")
                plt.ylabel(input.scattervars()[0])
            else:
                ax.scatter(filteredData()[list(input.scattervars())[0]], filteredData()[list(input.scattervars())[1]])
                plt.xlabel(input.scattervars()[0])
                plt.ylabel(input.scattervars()[1])
        elif input.plotType()=="hist":
            sv = req(input.singlevar())
            ax.hist(filteredData()[[input.singlevar()]])
            plt.xlabel(input.singlevar())
        elif input.plotType()=="box":
            sv = req(input.singlevar())
            # boxplot does not ignore nan by itself
            datanan = filteredData()[[input.singlevar()]]
            ax.boxplot(datanan.dropna())
            plt.ylabel(input.singlevar())
        return fig

app = App(app_ui, server)