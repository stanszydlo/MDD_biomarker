##############################################################################
#                          STAT 465 FINAL PROJECT
#
#                     Exploratory Demographic Analysis
#
#                               Stan Szydlo
##############################################################################

# Load Packages and Data .....................................................

  # getwd()
  setwd("/Users/stan/Desktop/stat465/Depression Biomarker Project")
  
  library(tidyverse)
  library(ggplot2)
  
  demog_data<- read_csv("data/clean_demog_data.csv")

# .............................................................................
  
  # Distibution of MDD diagnoses across gender
  demog_data%>% group_by(gender, mdd) %>% count(mdd)
  
  # %>%
  #   ggplot(aes(x = gender, y = n, fill= mdd)) +
  #   geom_bar(stat = "identity",position=position_dodge()) +
  #   ylab("Count") +
  #   xlab("Gender") +
  #   guides(fill=guide_legend(title="MDD Diagnosis")) +
  #   theme_minimal()
  
  # Distibution of MDD diagnosis across batch
  demog_data%>% group_by(batch, mdd) %>% count(mdd)

# .............................................................................

  # Distibution of anxiety across gender
  demog_data%>% group_by(gender, anxiety) %>% count(anxiety) 
  
  # Distibution of anxiety across batch
  demog_data%>% group_by(batch, anxiety) %>% count(anxiety)

# .............................................................................

  # Group 0 = CNTL no anxiety
  # Group 1 = MDD no anxiety
  # Group 2 = MDD with anxiety
  
  # Distibution of groups across gender
  demog_data%>% group_by(gender, group) %>% count(group)
  
  # Distibution of groups across batch
  demog_data%>% group_by(batch, group) %>% count(group)

# .............................................................................

  # distribution of age by gender
  demog_data%>% group_by(gender) %>% 
    ggplot(aes(x = gender, y = age, group = gender)) + 
    geom_jitter(alpha = 0.5, aes(color = gender)) +
    geom_boxplot(alpha = 0) + 
    coord_flip() +
    theme_minimal()
  
  # distribution of age by clinical group
  demog_data%>% group_by(group) %>% 
    ggplot(aes(x = group, y = age, group = group)) + 
    geom_jitter(alpha = 0.2) +
    geom_boxplot(alpha = 0) + 
    coord_flip() +
    theme_minimal()
  
  # distribution of age by batch
  demog_data%>% group_by(batch) %>% 
    ggplot(aes(x = batch, y = age, group = batch)) + 
    geom_jitter(alpha = 0.2) +
    geom_boxplot(alpha = 0) + 
    coord_flip() +
    theme_minimal()
