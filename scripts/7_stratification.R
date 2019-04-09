##############################################################################
#                           STAT 465 FINAL PROJECT
#
#                           Patient Stratification:
#              Discover biologically meaningful participant subgroups 
#
#                                Stan Szydlo
##############################################################################

  library(tidyverse)
  library(ggdendro)
  library(ggfortify)
  library(gplots) 
  
  big_data_ <- read_csv("data/clean_data.csv") 
  big_data <- data.frame(big_data_) %>% dplyr::select(5:ncol(big_data))
  rownames(big_data) <- big_data_$reference_ID
  
    batch_data <- big_data_ %>% 
      dplyr::select(batch, c(5:ncol(big_data))) %>% 
      mutate(batch = factor(batch))
    
    group_data <- big_data_ %>% 
      dplyr::select(group, c(5:ncol(big_data))) %>%
      mutate(group = plyr::revalue(factor(group), c("0" = "CNTL",
                                              "1" = "MDD",
                                              "2" = "MDD_&_Anxiety")))
  
  probes_genes <- read_csv("data/probes_genes.csv")
  
  data_q_ <- read_csv("data/data_q.csv")
  data_q <- data_q_ %>% dplyr::select(-reference_ID, -mdd, -anxiety, -group)
  rownames(data_q) <- data_q_$reference_ID
  colnames(data_q) <- probes_genes$SYMBOL[probes_genes$PROBEID %in% colnames(data_q)]
  data_q <- data.frame(data_q)
  
  
# Participant Hierarchical Clustering ......................................................

  # calculate correlation distance matrix 
  dd <- as.dist( (1 - cor( t( big_data[,-1]) ) ) / 2 )
  
  # perform hierarchical clustering
  hc <- hclust(dd)
  
  # convert cluster object to use with ggplot
  dendr <- dendro_data(hc, type="rectangle")
  
  colors <- sapply(big_data$group, 
                   function(x){ case_when(
                     x == 0 ~ "green",
                     x == 1 ~ "blue",
                     x == 2 ~ "red")
                   }
  )
  
  hier_tree <- ggplot() + # Dendrogram 
    geom_segment(data=segment(dendr), aes(x=x, y=y, xend=xend, yend=yend), color = "grey") +
    geom_text(data=label(dendr), aes(x=x, y=y, label=label, hjust=0), size=1.5, color = colors) +
    coord_flip() + scale_y_reverse(expand = c(0.2,0)) +
    theme(axis.line.y=element_blank(),
          axis.ticks.y=element_blank(),
          axis.text.y=element_blank(),
          axis.title.y=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(),
          axis.title.x=element_blank(),
          panel.background=element_rect(fill="white"),
          panel.grid=element_blank())
  
  hier_tree

# ..............................................................................

  rg=colorpanel(50, low="red", mid="black", high="chartreuse")
  heat_map <- heatmap(as.matrix(data_q[,-1]), col = rg)
  
  heat_map

# Principal Component Analysis .................................................
  
  res <- prcomp(batch_data[, -c(1:4)], center = TRUE, scale. = FALSE)
  
  perc_var_exp <- res$sdev^2/sum(res$sdev^2)
  
  plot(perc_var_exp,
       main = "Principal Components",
       ylab = "",
       xlab = "",
       pch = 1,
       type = "o",
       axes = FALSE)
  axis(2, ylim=c(0,0.4),col="black",las=1) # left axis 
  mtext("% Variance Explained",side=2,line=3)
  par(new=TRUE)
  plot(cumsum(perc_var_exp),
       ylab = "",
       xlab = "",
       pch = 1,
       type = "o",
       col = "red",
       axes = FALSE)
  mtext("Cumulative % Variance Explained",side=4, col="red", line=3) 
  axis(4, ylim=c(0,1), col="red",col.axis="red",las=1) # right axis 
  axis(1, seq(0,200)) # x axis
  mtext("Index",side=1,col="black",line=2.5)  
  grid()
  
  
  batch_pca_plot <- autoplot(res, data = batch_data, colour = "batch") + 
    theme_minimal() +
    theme(legend.position = c(0.65, 0.2)) +
    theme(legend.background = element_rect(fill= NA, 
                                           size=0.5,
                                           linetype="solid"))
  
  
  group_pca_plot <- autoplot(res, data = group_data, colour = "group") + 
    theme_minimal() +
    theme(legend.position = c(0.65, 0.2)) +
    theme(legend.background = element_rect(fill= NA, 
                                           size=0.5,
                                           linetype="solid"))
  
#  .............................................................................

  group_pca_plot 
  
  batch_pca_plot # batch effect observed






