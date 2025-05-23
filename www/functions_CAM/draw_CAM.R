# ==============================================================================
# R-Code - CAM
# date of creation: December 2021
# authors: Julius Fenn
# function: draw_CAM()
# ==============================================================================

############################################################################
# draw_CAM()
#
############################################################################
# dat_merged = CAMfiles[[3]]
# dat_nodes = CAMfiles[[1]]
# ids_CAMs = "all"
# plot_CAM = TRUE
# useCoordinates = TRUE
# relvertexsize = 7
# reledgesize = 1

# dat_merged = slicedCAMs_combined[[3]]
# dat_nodes = slicedCAMs_combined[[1]]
# ids_CAMs = "all"
# plot_CAM = FALSE
# useCoordinates = TRUE
# relvertexsize = 3
# reledgesize = 1


# dat_merged = slicedCAMs_seperated[[3]]
# dat_nodes = slicedCAMs_seperated[[1]]

# dat_merged = slicedCAMs_seperated[[6]]
# dat_nodes = slicedCAMs_seperated[[4]]
# ids_CAMs = "all"
# plot_CAM = FALSE
# useCoordinates = TRUE
# relvertexsize = 3
# reledgesize = 1


draw_CAM <- function(dat_merged = CAMfiles[[3]],
                     dat_nodes = CAMfiles[[1]],
                     ids_CAMs = "all", plot_CAM = FALSE, useCoordinates = TRUE,
                     relvertexsize = 5,
                     reledgesize = 1){

  ## create ids_CAMs
  if(length(ids_CAMs) == 1 && ids_CAMs == "all"){
    ids_CAMs <- unique(dat_merged$CAM.x)
  }

  if(!all(ids_CAMs %in% dat_nodes$CAM)){
    print("draw_CAM: using participant CAM ids")
    dat_merged$CAM.x <- dat_merged$participantCAM.x
    dat_nodes$CAM <-   dat_nodes$participantCAM
  }

  ## check ids_CAMs argument
  if(is.character(ids_CAMs) && (!all(ids_CAMs %in% unique(dat_merged$CAM.x)))){
    cat("Your specified ids are:", ids_CAMs, ", which is / are not matching the ids of the dataset (seperated by '//'):" ,"\n")
    cat(paste0(unique(dat_merged$CAM.x), collapse = " // "), "\n")
    stop("> Redefine ids")
  }



  # ## check ids_CAMs argument
  # if(!(all(is.character(ids_CAMs) & ids_CAMs == "all") | is.numeric(ids_CAMs))){
  #   cat("Your specified ids_CAMs argument is:", ids_CAMs, "\n")
  #   stop("> Use as argument \"all\" for drawing all posibble CAMs in dataset, or an id vector, like \"c(512, 533) \" for single CAMs")
  # }
  #
  # ## check ids_CAMs argument + create ids_CAMs
  # if(is.numeric(ids_CAMs) & !all(ids_CAMs %in% unique(dat_merged$CAM.x))){
  #   cat("Your specified ids are:", ids_CAMs, ", which is / are not matching the ids of the dataset (seperated by '//'):" ,"\n")
  #   cat(paste0(unique(dat_merged$CAM.x), collapse = " // "), "\n")
  #   stop("> Redefine ids")
  # } else if(is.character(ids_CAMs)){
  #   ids_CAMs <- unique(dat_merged$CAM.x)
  # }


  ## list for igraph objects
  list_g <- list()
  cat("processing", length(ids_CAMs), "CAMs...", "\n")

  ## try catch START 1
  for(i in 1:length(ids_CAMs)){
    # cat("processing", i, "\n")

    # temporary dataset merged dataset (multiple vertices -> mutal edges)
    tmp_dat_merged <- dat_merged[dat_merged$CAM.x == ids_CAMs[i], ]
    # temporary dataset blocks dataset (unique vertices)
    tmp_dat_nodes <- dat_nodes[dat_nodes$CAM == ids_CAMs[i], ] # ! not possible: information is in blocks dataset: tmp_data_blocks <- unique(tmp_data_merged[, c(1:13)])

    g_own <- igraph::graph.data.frame(as.data.frame(
      tmp_dat_merged[,c("id", "idending")]))





    # if all connections are bidirectional, treat network as undirected
    if(all(tmp_dat_merged$isBidirectional == 1)){
      g_own <- igraph::as.undirected(graph = g_own)
    }

    #################
    # aesthetical attributes
    #################
    ### unique ID
    V(g_own)$participantCAM <- unique(tmp_dat_nodes$participantCAM)
    ###################### > for vertex / vertices
    tmp_V_title <- c()
    tmp_V_value <- c()
    tmp_V_timestamp <- c()

    tmp_V_x_Pos <- c()
    tmp_V_y_Pos <- c()
    for(j in 1:length(V(g_own))){
      ## match by ID names in block data set
      if(any(colnames(tmp_dat_nodes) == "text_summarized")){
        tmp_V_title[j] <- tmp_dat_nodes$text_summarized[names(V(g_own))[j] == tmp_dat_nodes$id ]
      }else{
        tmp_V_title[j] <- tmp_dat_nodes$text[names(V(g_own))[j] == tmp_dat_nodes$id ]
      }

      tmp_V_value[j] <- tmp_dat_nodes$value[names(V(g_own))[j] == tmp_dat_nodes$id ]

      ## match by ID shape in block data set
      # tmp_V_shape[j] <- tmp_data_blocks$shape[names(V(g_own))[j] == tmp_data_blocks$id ]
      ## match by ID timestamp in block data set
      tmp_V_timestamp[j] <- tmp_dat_nodes$date[names(V(g_own))[j] == tmp_dat_nodes$id ]

      ## add coordinates
      tmp_V_x_Pos[j] <- tmp_dat_nodes$x_pos[names(V(g_own))[j] == tmp_dat_nodes$id ]
      tmp_V_y_Pos[j] <- tmp_dat_nodes$y_pos[names(V(g_own))[j] == tmp_dat_nodes$id ]

    }

    ## title vertex attributes:
    V(g_own)$label <- tmp_V_title

    ## colour vertex attributes:
    V(g_own)$color <- ifelse(test = tmp_V_value < 0, yes = "red",
                             ifelse(test = tmp_V_value == 0, yes = "yellow",
                                    no = ifelse(test = tmp_V_value == 10, yes = "purple",
                                                no = ifelse(test = tmp_V_value > 0 & tmp_V_value < 10, yes = "green", no = "ERROR"))))



    ## position vertex attributes
    V(g_own)$xPos <- tmp_V_x_Pos
    V(g_own)$yPos <- tmp_V_y_Pos


    ## colour vertex attributes:
    V(g_own)$shape <- ifelse(test = V(g_own)$color == "green", yes = "circle",
                             ifelse(test = V(g_own)$color == "red", yes = "rectangle",
                                    no = ifelse(test = V(g_own)$color == "purple", yes = "sphere",
                                                no = ifelse(test = V(g_own)$color == "yellow", yes = "square", no = "ERROR"))))

    ## title color vertex attributes:
    V(g_own)$label.color <- "black" # text black

    ## title font vertex attributes:
    V(g_own)$label.font <- 1 # 2 = bold

    ## value (no aesthetical attribute -> save values)
    # tmp_V_value[tmp_V_value==10] <- 0
    V(g_own)$value <- tmp_V_value

    ## timestamp (no aesthetical attribute -> save values)
    # > all missing timestamps to NA
    tmp_V_timestamp[tmp_V_timestamp == ""] <- NA
    V(g_own)$timestamp <- tmp_V_timestamp

    ## size vertex attributes based on defined relvertexsize:
    V(g_own)$size <- as.numeric(ifelse(test = abs(tmp_V_value) == 3, yes = relvertexsize*4,
                                       ifelse(test = abs(tmp_V_value) == 2, yes =relvertexsize*3,
                                              no = ifelse(test = abs(tmp_V_value) == 1, yes =relvertexsize*2,
                                                          no = ifelse(test = abs(tmp_V_value) == 10, yes = relvertexsize*1,
                                                                      no = ifelse(abs(tmp_V_value) == 0, yes =relvertexsize*1, no = "ERROR"))))))



    ###################### > edges
    tmp_E_intensity <- c()
    tmp_E_agreement <- c()
    for(j in 1:length(E(g_own))){
      tmp_E_intensity[j] <- tmp_dat_merged$intensity[ends(g_own, E(g_own))[j,1] == tmp_dat_merged[,"id"] &
                                                       ends(g_own, E(g_own))[j,2] == tmp_dat_merged[,"idending"]]
      tmp_E_agreement[j] <- tmp_dat_merged$agreement[ends(g_own, E(g_own))[j,1] == tmp_dat_merged[,"id"] &
                                                       ends(g_own, E(g_own))[j,2] == tmp_dat_merged[,"idending"]]
    }

    ## width of lines based on defined reledgesize:
    E(g_own)$width <- as.numeric(ifelse(test = tmp_E_intensity == 3, yes = reledgesize,
                                        ifelse(test = tmp_E_intensity == 6, yes = reledgesize*3,
                                               no = ifelse(test = tmp_E_intensity == 9, yes = reledgesize*5, no = "ERROR"))))


    E(g_own)$weight <- tmp_E_intensity / 3 # !!!
    ### colour of lines
    E(g_own)$color <- "grey"

    ### linetyp
    E(g_own)$lty <- as.numeric(ifelse(test = tmp_E_agreement == 1, yes =  1,
                                      ifelse(test = tmp_E_agreement == 0, yes = 2, no = "ERROR")))




    #################
    # draw network
    #################
    ############### > static graph
    if(plot_CAM){
      if(useCoordinates){
        plot(g_own, edge.arrow.size = .1, layout=cbind(V(g_own)$xPos, V(g_own)$yPos),
             vertex.frame.color="black")
      }else{
        # adjust?
        plot(g_own, edge.arrow.size = .1, layout=layout_nicely, vertex.frame.color="black")
        title(paste0("CAM:", ids_CAMs[i]), cex.main=1)
      }
      title(paste0("CAM:", ids_CAMs[i]), cex.main=1)
    }


    list_g[[i]] <- g_own
  }
  ## set participantCAM as default ID if unique and all IDs are provided
  if(length(unique(dat_merged$participantCAM.x)) == length(unique(dat_merged$CAM.x)) &
     !any(dat_merged$participantCAM.x %in% c("NO ID PROVIDED", "noID"))){
    if(length(ids_CAMs) < length(unique(dat_merged$participantCAM.x))){
      print("provided participantCAM ID in drawnCAM")
      names(list_g) <-  paste0(ids_CAMs)
    }else{
      print("== participantCAM in drawnCAM")
      names(list_g) <- unique(dat_merged$participantCAM.x)
    }

  }else{
    print("== ids_CAMs in drawnCAM")
    names(list_g) <- paste0(ids_CAMs)
  }
  ## try catch START 2


  return(list_g)
}



## try catch START 1
# tryCatch({
## try catch START 2
#   }, # tryCatch(): catch warnings
# warning = function(cond) {
#   showModal(
#     modalDialog(
#       title = "Error while drawing CAMs",
#       "It appears that the data of at least one of the CAMs is invalid. This could happen e.g. if the data file is corrupt. Please make sure you have uploaded the right data set.",
#       easyClose = TRUE,
#       footer = tagList(modalButton("Ok"))
#     )
#   )
# },
#
# # tryCatch(): catch errors
# error = function(cond) {
#   showModal(
#     modalDialog(
#       title = "Error while drawing CAMs",
#       "It appears that the data of at least one of the CAMs is invalid. This could happen e.g. if the data file is corrupt. Please make sure you have uploaded the right data set.",
#       easyClose = TRUE,
#       footer = tagList(modalButton("Ok"))
#     )
#   )
# }
# ) # tryCatch()
#
