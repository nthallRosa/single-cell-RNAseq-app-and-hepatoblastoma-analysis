source("backend.R")

# Define UI for application that draws a histogram
ui <- dashboardPage(
        skin = "purple",
        dashboardHeader(title = "scRNAseq Analysis"),
        dashboardSidebar(width = 255,
                         tags$head(
                                 tags$style(HTML(".skin-blue .main-header .sidebar-toggle {display: none;}"))
                         ),
                         sidebarMenu(id="tab",
                                     menuItem("Home Page", tabName = "home", icon = icon("list")),
                                     menuItem("Data Explorer", tabName = "input", icon = icon("edit")),
                                     menuItem("DE Analysis", tabName = "de", icon = icon("chart-bar")),
                                     conditionalPanel(condition = "input.tab == 'input'",
                                                      div(
                                                              fileInput("file", "Upload File", multiple=FALSE, accept=c('.rds')),
                                                              actionButton("reset", "Reset", icon = icon("undo"), style = "color: #fff; background-color: #dc3545; width: 87.25%"),
                                                              actionButton("run", "Run", icon = icon("play"), style = "color: #fff; background-color: #28a745; width: 87.25%"),
                                                              checkboxInput("group_compare", "Comparing multiple conditions?", value = FALSE)
                                                      )
                                     )
                         )
        ),
        dashboardBody(
                useShinyjs(),
                tabItems(
                        tabItem(tabName = "input",
                                tabsetPanel(id = "main_tabs",
                                            tabPanel("Instructions",
                                                     includeMarkdown('./markdown/Instructions.Rmd')
                                            )
                                )
                        ),
                        
                        tabItem(tabName = "home",
                                tags$h1(HTML("Welcome to the Seurat single cell app")),
                                div(style = "text-align: center;",
                                imageOutput("single_cell_image"))
                        ),
                        
                        tabItem(tabName = "de",
                                tabsetPanel(id = "de_tabs",
                                            tabPanel("Tables",
                                                     uiOutput("de_selection_ui")
                                            ),
                                            tabPanel("Visualizations",
                                                     uiOutput("de_visuals_ui"))
                                )
                        )
                )
        )
)
# Define server logic required to draw a histogram
server <- function(input, output, session) {
        options(shiny.maxRequestSize = 1000 * 1024^2)
        
        output$single_cell_image <- renderImage({
                list(
                        src = "title_image.png",
                        width = 550,
                        height = 400
                )
        }, deleteFile = FALSE)
        
        # In order for users to properly reset a run, data from the previous 
        # one will need to be cleared. The includes the differential expression analysis table
        # (de_result_rv), the seurat object (obj_rv), celltypes used for visualizations, and 
        # the selection of multiple comparisons or not (multiple), and the plot_data for the 
        # DE analyzer panel. Creation of reactive variables also ensures that functions (like the 
        # Downloadhandler) outside the observeEvents for DE analysis and Visualizations 
        # can access the tables and plots that outputs from it.
        de_result_rv <- reactiveVal(NULL)
        obj_rv       <- reactiveVal(NULL)
        celltypes    <- reactiveVal(NULL)
        multiple     <- reactiveVal(NULL)
        plot_data    <- reactiveVal(NULL)
        
        shinyjs::disable('run')
        
        # checks to see if a file has been uploaded. If not the run 
        # button is disabled.
        observe({
                if (is.null(input$file) !=TRUE){
                        shinyjs::enable('run')
                }   else {
                        shinyjs::disable('run')
                }
        })

        
        observeEvent(input$run, {
                shinyjs::reset("file")
                shinyjs::disable("run")
                shinyjs::disable("group_compare")
                removeTab('main_tabs', 'UMAP')
                removeTab('main_tabs', 'Gene Expression')
                # clears the contents ui of the DE analysis panel
                output$de_selection_ui <- renderUI({return(NULL)})
                output$de_visuals_ui <- renderUI({return(NULL)})
                de_result_rv(NULL)
                obj_rv(NULL)
                celltypes(NULL)
                multiple(NULL)
                plot_data(NULL)
                
                
                show_modal_spinner(text = "Preparing plots...")
                obj <- load_seurat_obj(input$file$datapath)
                if (is.vector(obj)){
                        showModal(modalDialog(
                                title = "Error with file", HTML("<h5>There 
                   is an error with the file you uploaded. See below for more details.</h5><br>",
                                                                paste(unlist(obj), collapse = "<br><br>"))))
                        shinyjs::enable("run")
                        
                }
                        obj_rv(obj) 
                        
                        output$umap <- renderPlot({
                                create_metadata_UMAP(obj_rv(), input$metadata_col)
                        })
                        
                        output$featurePlot <- renderPlot({
                                create_feature_plot(obj_rv(), input$gene)
                        })
                        
                        output$downloadFeaturePlot <- downloadHandler(
                                filename = function(){
                                        paste0(input$gene, '_feature_plot', '.png')
                                },
                                content = function(file){
                                        plot <- create_feature_plot(obj_rv(), input$gene)
                                        ggsave(filename=file, width = 10, height = 5, type = "cairo")
                                }
                        )
                        output$download_umap <- downloadHandler(
                                filename = function(){
                                        paste0(input$metadata_col, '_UMAP', '.png')
                                },
                                content = function(file){
                                        plot <- create_metadata_UMAP(obj_rv(), input$metadata_col)
                                        ggsave(filename=file, width = 10, height = 5, type = "cairo")
                                }
                        )
                        output$download_DE_table <- downloadHandler(
                                filename = function(){
                                        paste0(input$g1, '_', input$g2, '_DE_analysis', '.csv')
                                },
                                content = function(file){
                                        write.csv(de_result_rv(), file)
                                }
                        )
                        output$download_vis <- downloadHandler(
                                filename = function(){
                                        paste0(input$vis_op, '_visualization', '.PNG')
                                },
                                content = function(file){
                                        pd <- plot_data()
                                        ggsave(filename=file, width = 10, height = 5, type = "cairo")
                                }
                        )
                        
                        insertTab(
                                inputId = "main_tabs",
                                tabPanel(
                                        "UMAP",
                                        fluidRow(
                                                column(
                                                        width=8,
                                                        plotOutput(outputId = "umap"),
                                                        downloadButton('download_umap', "Download UMAP")
                                                ),
                                                column(
                                                        width=4,
                                                        selectizeInput('metadata_col',
                                                                       "Metadata Column",
                                                                       colnames(obj@meta.data))
                                                )
                                        )
                                )
                        )
                        
                        insertTab(
                                inputId = "main_tabs",
                                tabPanel(
                                        "Gene Expression",
                                        fluidRow(
                                                column(
                                                        width = 8,
                                                        plotOutput(outputId = 'featurePlot'),
                                                        downloadButton("downloadFeaturePlot", "Download Feature Plot")
                                                ),
                                                column(
                                                        width = 4,
                                                        selectizeInput("gene", "Genes", 
                                                                      choices = NULL
        
                                                        )
                                                )
                                        ),
                                        style = "height: 90%; width: 95%; padding-top: 5%;"
                                )
                        )
                        
                        updateSelectizeInput(session, 'gene', choices = rownames(obj), server = TRUE)
                        
                        
                        output$de_selection_ui <- renderUI({
                                fluidRow( 
                                        column(width = 4, selectizeInput("g1", "Group 1", levels(obj@active.ident))),
                                        column(width = 4, selectizeInput("g2", "Group 2", levels(obj@active.ident))),
                                        column(width = 4, div(actionButton("de_analysis", "Run Analysis", icon = icon("play"), style = "color: white; background-color: purple;"),
                                                             style = "position: absolute; top: 25px;"
                                        ))
                                )
                        })
                        
                        observeEvent(input$group_compare, {
                                if (input$group_compare == TRUE) {
                                        celltypes(celltype_extract(obj))
                                        multiple(TRUE)
                                } else {
                                        celltypes(levels(obj@active.ident))
                                        multiple(FALSE)
                                }
                        })
                        
                        
                        output$de_visuals_ui <- renderUI({
                                req(obj_rv())
                                obj <- obj_rv()
                                tagList(
                                        fluidRow(
                                                column(width = 2, radioButtons("vis_op", "Visualization:",
                                                                               choices = c("Violin" = "vln", "Dot plot" = "dot", "Feature plot" = "fp"))),
                                                column(width = 4, selectizeInput("g", "Group", choices = NULL, multiple = TRUE)),
                                                column(width = 4, selectizeInput("gene2", "Genes", choices = NULL, multiple = TRUE))
                                        ),
                                        fluidRow(
                                                column(width = 3, offset = 9, selectizeInput('metadata_col2',
                                                                                             "Split by", colnames(obj@meta.data))),
                                                column(width = 4, offset = 9, div(
                                                        actionButton("vis_output", "Create plot", icon = icon("play"),
                                                                     style = "color: white; background-color: purple;"),
                                                        style = "position: absolute; top: 25px;"))
                                        ),
                                        fluidRow(
                                                column(width = 9, div(style = "text-align: center;",plotOutput("vis_plot"))),
                                                column(width = 6, downloadButton('download_vis', 'Download visualization'))
                                        )
                                )
                        })
                        
                        
                        
                        remove_modal_spinner()
                        shinyjs::enable("run")
                })
                
                        
                        observeEvent(input$de_analysis, {
                                obj <- obj_rv()
                                req(obj)
                                req(input$g1, input$g2)
                                
                                if (input$g1 == input$g2) {
                                        showModal(modalDialog(
                                                title = "Invalid selection",
                                                "Group 1 and Group 2 must be different."
                                        ))
                                        return()
                                }
                                
                                show_modal_spinner(text = "Running DE analysis...")
                                de_result <- de_analysis(obj, input$g1, input$g2)
                                
                                if (is.null(de_result)) return()
                                
                                de_result_rv(de_result)
                                output$de_table <- DT::renderDT(DT::datatable(de_result))
                                remove_modal_spinner()
                                
                                
                                output$de_selection_ui <- renderUI({
                                        tagList(
                                                fluidRow(
                                                        column(width = 4, selectizeInput("g1", "Group 1", levels(obj@active.ident), selected = input$g1)),
                                                        column(width = 4, selectizeInput("g2", "Group 2", levels(obj@active.ident), selected = input$g2)),
                                                        column(width = 4, div(actionButton("de_analysis", "Run Analysis", icon = icon("play"), 
                                                                                           style = "color: white; background-color: purple;"),
                                                                              style = "position: absolute; top: 25px;"))),
                                                fluidRow(
                                                        column(width = 12, 
                                                               DT::DTOutput(outputId = "de_table"),
                                                               downloadButton('download_DE_table', "Download DE output"))
                                                        
                                                )
                                        )
                                })
                                
                                
                        })
                        
                        # users can choose up to 13 genes for the dot plot and only one gene for the 
                        # feature and violin plots. Users can select up to 8 celltypes for the dot and violin plots.
                        # No cell types are selected for feature plots.
                        observeEvent(input$vis_op, {
                                if (input$vis_op == "fp") {
                                        shinyjs::disable("g")
                                } else{
                                        shinyjs::enable("g")
                                }

                                max_genes <- if (input$vis_op == "dot") 13 else 1
                                
                                updateSelectizeInput(
                                        session,
                                        inputId = "gene2",
                                        choices = rownames(obj_rv()),
                                        selected = isolate(input$gene2)[seq_len(min(max_genes, length(isolate(input$gene2))))],
                                        options = list(maxItems = max_genes),
                                        server = T
                                )
                                
                                max_groups <- if (input$vis_op %in% c("dot", "vln")) 8 else 1
                                
                                updateSelectizeInput(
                                        session,
                                        inputId = "g",
                                        choices = celltypes(),
                                        selected = ,
                                        options = list(maxItems = max_groups),
                                        server = T
                                )
                                
                                
                        })
                        # When the run button (vis_output) is selected, the inputs necessary to generate the plots are stored
                        # in plot_data. Plot_data will then be used to render each plot and users can switch between 
                        # the 3 visualizations. Storing inputs in plot_data ensures that the rendering of
                        # new plots is controlled only by the run button and not any changes to the input values.
                        observeEvent(input$vis_output, {
                                plot_data(list(
                                        features = input$gene2,
                                        group_by = input$g,
                                        split_by = input$metadata_col2,
                                        obj = obj_rv(),
                                        vis_op = input$vis_op
                                ))
                        })
                                
                                output$vis_plot <- renderPlot({
                                        pd <- plot_data()  # only reacts to plot_data(), never to input$gene_select directly
                                        req(pd$features, pd$group_by)
                                        
                                        switch(input$vis_op,
                                               "dot" = tryCatch(
                                                       {de_vis(pd$obj, pd$features, pd$group_by, pd$split_by, multiple.groups = multiple())
                                               }, error = function(e) {
                                                       showModal(modalDialog(
                                                               title = "Invalid selection",
                                                               "Selected genes are not expressed in celltypes"
                                                       ))
                                                       return(NULL)
                                               }),
                                               "vln" = de_vis(pd$obj, pd$features, pd$group_by, pd$split_by, v1 = F, v2 = F, v3 = T, multiple()),
                                               "fp"  = de_vis(pd$obj, pd$features, pd$group_by, pd$split_by, v1 = F, v2 = T, v3 = F, multiple())
                                        )
                                })
                
                        
        
        
        # Clear all sidebar inputs when 'Reset' button is clicked
        observeEvent(input$reset, {
                shinyjs::reset("file")
                removeTab("main_tabs", "UMAP")
                removeTab("main_tabs", "Gene Expression")
                output$de_selection_ui <- renderUI({return(NULL)})
                output$de_visuals_ui <- renderUI({return(NULL)})
                plot_data(NULL)
                de_result_rv(NULL)
                obj_rv(NULL)
                celltypes(NULL)
                multiple(NULL)
                shinyjs::disable("run")
                shinyjs::enable("group_compare")
        })
}        

shinyApp(ui = ui, server = server)
