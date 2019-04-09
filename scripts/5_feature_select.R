##############################################################################
#                         STAT 465 Final Project
#
#                           Feature Selection 
#
#                             Stan Szydlo
##############################################################################

  library(tidyverse)
  library(ggfortify)
  library(plotly)

  big_data <- read_csv("data/clean_data.csv")
  mdd_probes_q <- read_csv("data/mdd_probes_q.csv")
  
  alpha_level = 0.35
  
  # select top probes 
  q_top <- mdd_probes_q %>% filter(q_value<=alpha_level)
  
  data_q <- big_data %>% dplyr::select(reference_ID, mdd, anxiety,  group, q_top$probes)
  
  #write_csv(data_q,"data/data_q.csv")

