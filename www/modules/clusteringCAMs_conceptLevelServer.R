clusteringCAMs_conceptLevelServer <-
  function(id, dataCAM, drawnCAM, parent, globals) {
    moduleServer(id, function(input, output, session) {
      ns <- NS(id)

      ## reactive values
      outUI <- reactiveValues(elements = NULL)

      ################
      # default text + set output
      ################
      ## default text
      outUI$elements <- tagList(tags$div(
         h1("Clustering CAMs - on concept level"),
        tags$br(),
        tags$br(),
        HTML(
          'To start the module please click on one of the module options on the sidebar panel. The options for
                     this module are the following:'
        ),
              tags$ul(
              tags$li(HTML('<b>Concept co-occurrences:</b> Computing the concept-cooccurrences between all CAMs by setting up multiple contingency tables, followed by computing the phi coefficient, groups of concepts with similar concept-cooccurrences in CAMs are identified.')),
              tags$li(HTML('Valence co-occurrences: Computing hierarchical clustering over the given valence over all overlapping words between CAMs to identify similar CAMs.'))
            )
      ))

      ## set output
      output$uploadOutClusteringCAMsConceptLevel <- renderUI({
        outUI$elements
      })

      ################################
      # single module options
      ################################
        ###### ConceptCooccurrences
        #> UI
        observeEvent(input$ConceptCooccurrences, {

          ## change UI
          outUI$elements <- tagList(
          tags$h2("Concept co-occurrences"),
          tags$br(),
          tags$div(HTML("After choosing your settings (in most cases the default is recommended), please click on the draw heatmap button. 
          Please click only once and wait few seconds:"), style="font-size:14px"),
            tags$h3("Your Settings:"),
                     tags$div(
            HTML(
              'Please select if you want to consider the given valence to the concepts by the participants 
              (if yes Cohens Kappa is computed, if no the Phi coefficient is computed). Additionally you can choose if the heatmap should be 
              calculated on the summarized concepts (yes is recommended):'
            ),
            style = "font-size:14px"
          ),
          div(
            style = "margin: 0 auto; width: 100%; text-align:left;",
            div(
              style = "display: inline-block; vertical-align: top; width: 35%; padding:10px;",
			  # position
                       tags$div(HTML("Please specify if given valence to the concepts by the participants should be considered:"), style="font-size:14px"),
                   radioButtons(ns("drawHeatmap_setting_valence"), label = NULL, c("Yes", "No"), selected = "Yes"),
            ),
      div(
              style = "display: inline-block; vertical-align: top; width: 35%; padding:10px;",
			  # relative size of the vertices
		                     tags$div(HTML("Choose if the heatmap should be calculated on the summarized concepts:"), style="font-size:14px"),
                   radioButtons(ns("drawHeatmap_setting_summarized"), label = NULL, c("Yes", "No"), selected = "Yes"),
            ),
          ),
          tags$h3("Draw Heatmap:"),
            actionButton(ns("clickDrawHeatmap"), "draw Heatmap"),
            tags$p(
              "Your have currently considered ",
              tags$b(textOutput(ns("numConceptsHeatmap"), inline = TRUE), " (summarized) concepts"),
              " in your drawn heatmap."
            ),
            tags$br(),
            tags$br(),
                      tags$h4("Static Heatmap:"),
            plotOutput(ns("plotHeatmap"), width = "95%"),
                      tags$br(),
            tags$br(),
            tags$h4("Dynamic Heatmap:"),
            uiOutput(ns("plotHeatmapDynamic"))
          )
        })



        #> Server
        CorrSigTables <-
  eventReactive(input$clickDrawHeatmap,{
    ## get list of concepts
          if(input$drawHeatmap_setting_summarized == "Yes"){
            tmp_listConcepts <- listConcepts(datCAM = globals$dataCAMsummarized[[1]], useSummarized = TRUE, removeSuffix = TRUE)
          }else{
            tmp_listConcepts <- listConcepts(datCAM = globals$dataCAMsummarized[[1]], useSummarized = FALSE, removeSuffix = TRUE)
          }

    ## get all concepts >= 2
      tmp_countDuplicates <- countDuplicates(concepts = tmp_listConcepts, orderFrequency = TRUE)

    ## get CAMs x Concepts (1 = drawn)
    tmp_binaryEncoding <- binaryEncoding(conDF = tmp_listConcepts, duplDF = tmp_countDuplicates)


     if(input$drawHeatmap_setting_valence == "Yes"){
            tmp_CorrSigTables <- correlationTable(conList = tmp_countDuplicates,
                                  inputTable =  tmp_binaryEncoding, # metricDF
                                  CorrFUNC = cohensKappa, considerValence = TRUE,
                                  datNodes = globals$dataCAMsummarized[[1]])
    }else{
      tmp_CorrSigTables <- correlationTable(conList = tmp_countDuplicates,
                                  inputTable =  tmp_binaryEncoding, # metricDF
                                  CorrFUNC = phiCoefficient, considerValence = FALSE,
                                  datNodes = globals$dataCAMsummarized[[1]])
      }

      print("input$drawHeatmap_setting_valence")
      print(input$drawHeatmap_setting_valence)

names(tmp_CorrSigTables) <- c('coefficient', 'p')

## Extracting separate matrices for correlation coefficients and p values and filtering out rows/columns with NA only ##
coefficientMatrix <- as.matrix(tmp_CorrSigTables[["coefficient"]])
coefficientMatrix <- coefficientMatrix[rowSums(!is.na(coefficientMatrix))>1,
                                       colSums(!is.na(coefficientMatrix))>1]
pMatrix <- as.matrix(tmp_CorrSigTables[["p"]])
pMatrix <- pMatrix[rowSums(!is.na(pMatrix))>1,
                   colSums(!is.na(pMatrix))>1]


      return(list(coefficientMatrix, pMatrix))
  })


        ## summary stats:
        output$numConceptsHeatmap <- renderText({
          req(CorrSigTables())

          nrow(CorrSigTables()[[1]])
        })



        ## plot heatmap
        output$plotHeatmap <- renderPlot({
          req(CorrSigTables())
          
          heatmap(x = CorrSigTables()[[1]], col = brewer.pal(n = 5, name = "Paired"))
          legend(x = "bottomright", legend = c("very low", "low", "medium", "high","very high"),
       cex = 0.9, fill =  brewer.pal(n = 5, name = "Paired"))
        })



          output$plotHeatmapDynamic <- renderUI({
                      req(CorrSigTables())
interactiveHeatmap <- heatmaply_cor(
  CorrSigTables()[[1]],
  node_type = "scatter",
  point_size_mat = -log10(CorrSigTables()[[2]]),
  point_size_name = "-log10(p-value)",
  xlab = "Concepts",
  ylab = "Concepts",
  k_col = 2,
  k_row = 2,
  label_names = c("x", "y", "Correlation")
)

interactiveHeatmap  %>% plotly::layout(height=1200,width=1200)
  })



       ###### ValenceCooccurrences
        #> UI
        observeEvent(input$ValenceCooccurrences, {

          ## change UI
          outUI$elements <- tagList(
          tags$h2("Valence co-occurrences"),
         tags$br(),
          tags$div(HTML("Please click on the get valence co-occurrences button. 
          Please click only once and wait few seconds."), style="font-size:14px"),
          tags$h3("get valence co-occurrences:"),
            actionButton(ns("clickGetValenceCooccurrences"), "get valence co-occurrences"),
                      tags$div(HTML("The resulting dendrogram is clustering the CAMs (numbers of x-axis) according to the 
                      given valence to the (summarized) concepts by the participants:"), style="font-size:14px"),
                 fluidRow(
          column(7,plotOutput(ns("plotDendrogram_clustering"), width="100%")),  
          column(3,verbatimTextOutput(ns("numberGroupsText_clustering")))
        ),
            tags$div(HTML("Please cut the dendrogram by specifying the cutting height (horizontal red line):"), style="font-size:14px"),
       div(
            style = "margin: 0 auto; width: 100%; text-align:left;",
            div(
              style = "display: inline-block; vertical-align: top;",
 numericInput(ns("cuttingDendrogram_clustering"), label = NULL, value = 15, min = .5, max = 30, step = 1, width = "150px"),
            ),
       ),
                      tags$p(
      "Your uploaded CAM dataset contains ",
      tags$b(textOutput(ns(
        "Nodes_unique_clustering"
      ), inline = TRUE), " unique concepts"),
      " , whereby on your specified cutting height ",
      tags$b(
        textOutput(ns("numberGroups_clustering"), inline = TRUE),
        " groups of similar CAMs"
      ),
      " were identified by the given valence to the (summarized) concepts have been found."
    ),
    tags$h3("get average valences to interpret clusters:"),
    verbatimTextOutput(ns("getAverageValences_clustering"))
          )
        })


        #> Server
      # > unique concepts
      output$Nodes_unique_clustering <- renderText({
        length(unique(globals$dataCAMsummarized[[1]]$text))
      })

      ## compute hierarchical clustering
    observeEvent(input$clickGetValenceCooccurrences, {

################
# get data set
################
## remove suffix
globals$dataCAMsummarized[[1]]$text_summarized_suffremoved <- str_remove(string = globals$dataCAMsummarized[[1]]$text_summarized, 
pattern = "_neutral|_positive|_negative|_ambivalent")

## ID vars
hc_dat <- data.frame(CAM = unique(globals$dataCAMsummarized[[1]]$CAM), participantCAM = unique(globals$dataCAMsummarized[[1]]$participantCAM))
## word vars
for(w in unique(globals$dataCAMsummarized[[1]]$text_summarized_suffremoved)){
  varName_w <- str_remove_all(string = str_to_title(string = w, locale = "en"), pattern = " |\\W+")

  hc_dat[[paste0("N_", varName_w)]] <- NA
  hc_dat[[paste0("mean_", varName_w)]] <- NA
  hc_dat[[paste0("SD_", varName_w)]] <- NA
}

#############
## get N, mean, sd of single summarized concepts
verbose = FALSE

for(c in unique(globals$dataCAMsummarized[[1]]$CAM)){
  if(verbose){
      cat("considered CAM: ", c, "\n")
  }
  tmp_CAM_nodes <- globals$dataCAMsummarized[[1]][globals$dataCAMsummarized[[1]]$CAM == c, ]
  tmp_CAM_nodes$value <- ifelse(test = tmp_CAM_nodes$value == 10, yes = 0, no = tmp_CAM_nodes$value)

  for(w in unique(globals$dataCAMsummarized[[1]]$text_summarized_suffremoved)){
      if(verbose){
    cat("considered concept: ", w, "\n")
      }

    varName_w <- str_remove_all(string = str_to_title(string = w, locale = "en"), pattern = " |\\W+")
          if(verbose){
    cat("   > the freqeuncy, mean, SD are saved with the prefix N_, mean_, SD_ plus
      word without white spaces: ", varName_w, "\n")
          }

    if(sum(tmp_CAM_nodes$text_summarized_suffremoved == w) > 0){
      tmp_CAM_nodes_w <- tmp_CAM_nodes[tmp_CAM_nodes$text_summarized_suffremoved == w, ]

      ## add N
      hc_dat[hc_dat$CAM == c, paste0("N_", varName_w)] <- nrow(tmp_CAM_nodes_w)
      ## add mean
      hc_dat[hc_dat$CAM == c, paste0("mean_", varName_w)] <- mean(x = tmp_CAM_nodes_w$value)
      ## add SD, only if > 1
      hc_dat[hc_dat$CAM == c, paste0("SD_", varName_w)] <- sd(x = tmp_CAM_nodes_w$value)
    }
  }
        if(verbose){
  cat("\n")
        }
}
#############


################
# compute clustering
################
### data set
hc_df <- hc_dat[, str_subset(string = colnames(hc_dat), pattern = "mean_")]
hc_df_scaled <- scale(hc_df)

### run Hierarchical Clustering
dist.eucl <- dist(hc_df_scaled, method = "euclidean")

hc_cluster <- hclust(dist.eucl, method = "ward.D2") # Ward's method


        ## get dendogram
        output$plotDendrogram_clustering <- renderPlot({
          plot(hc_cluster)
          abline(h = input$cuttingDendrogram_clustering, col = "red", lty = 2)
          rect.hclust(hc_cluster, h=input$cuttingDendrogram_clustering, border = "tomato")
        })


        ## get number of groups found text
        output$numberGroupsText_clustering <- renderPrint({
          groups<-cutree(hc_cluster, h=input$cuttingDendrogram_clustering)
          groupsOut <- names(table(groups))[table(groups) >= 2]

          print("total number of groups >= 2:")
          print(length(groupsOut))
          })

        ## get number of groups found
        output$numberGroups_clustering <- renderText({
          groups <-cutree(hc_cluster, h=input$cuttingDendrogram_clustering)
          max(groups)
      })

       ## get average valences to interpret clusters
        output$getAverageValences_clustering <- renderPrint({
### get average values to interpret cluster
          groups <-cutree(hc_cluster, h=input$cuttingDendrogram_clustering)
          aggregate(hc_df, by=list(cluster=groups), mean, na.rm = TRUE)
          })
    })


        ###### information
        observeEvent(input$informationClusteringCAMsConceptLevel, {
          ## change UI
          outUI$elements <- tagList(
            tags$h2("Module Specific Information"),
            tags$div(
              HTML('The options for this module are the following:'),
              tags$ul(
                tags$li(HTML('<b>Concept co-occurrences:</b> Computing the concept-cooccurrences between all CAMs by setting up multiple contingency tables, followed by computing the phi coefficient, groups of concepts with similar concept-cooccurrences in CAMs are identified.')),
                tags$li(HTML('Valence co-occurrences: Computing hierarchical clustering over the given valence over all overlapping words between CAMs to identify similar CAMs.'))
            )
          )
          )
        })

    })
    }