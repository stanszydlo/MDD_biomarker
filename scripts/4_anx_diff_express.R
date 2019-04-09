##############################################################################
#                            STAT 465 FINAL PROJECT
#
#                   Anxiety Differential Expression Analysis:
#             Discover a panel of probes that significantly distinguish 
#               clinically anxious patients from healthy controls
#
#                                 Stan Szydlo
##############################################################################

# Load Packages & Data .......................................................

  #getwd()
  setwd("/Users/stan/Desktop/stat465/Depression Biomarker Project")
  
  #source("http://www.bioconductor.org/biocLite.R")
  #biocLite("multtest")
  #biocLite("qvalue")
  
  library(multtest)
  library(qvalue)
  library(affy)
  library(knitr)
  library(tidyverse)
  library(ggplot2)
  library(scales)
  
  pcnorm <- read.table("data/GSE98793_norm.txt")
  demog <- read_csv("data/clean_demog_data.csv")
  probes <- rownames(pcnorm)


# Two sample t-test with equal variance .........................................

  # Assign class label (0 == No Anxiety, 1 = Anxiety)
  pcnorm_cl <- as.integer(demog$anxiety)
  
  # Calculate t-statistic for each probe assuming equal variance 
  teststat <- mt.teststat(pcnorm, test="t.equalvar", pcnorm_cl)
  
  # calculate raw p-value
  df = length(pcnorm)-2 # n1 + n2 - 2
  rawp0<-2*(1-pt(abs(teststat), df))
  
  # Visualize Raw Distribution
  rawhist <- hist(rawp0,
                  breaks = c(seq(0,1,0.05)), 
                  plot = FALSE)
  plot(x = seq(0.05,1,0.05),
       y = rawhist$count, 
       log="y",
       xlab = "p",
       ylab = "frequency",
       main = "raw p-values",
       type = "h",
       lwd=10,
       lend=2,
       col="blue")
  
  # adjust p-value by different methods
  procs <- c("Bonferroni", "Holm", "Hochberg", "SidakSS", "SidakSD","BH", "BY")
  res <- mt.rawp2adjp(rawp0, procs)
  
  # sort the adjusted p-value to original order and add probe labels
  adjp <- res$adjp[order(res$index), ]
  adjp_probes <- data.frame(probes, adjp) 
  
  # Visualize adjusted distribution
  adjhist <- hist(res$adjp[,2],
                  breaks = seq(0,1,0.05),
                  plot = FALSE)
  plot(x = seq(0.05,1,0.05),
       y = adjhist$count, 
       log="y",
       xlab = "p",
       ylab = "frequency",
       main = "Bonferri Adjusted p-values",
       type = "h",
       lwd=10,
       lend=2,
       col="blue")

# .............................................................................
  
  alpha_level = 0.1
  
  # Which probes are significant if controlling family-wise error rate at 0.1?
  sig_bonf_index <- adjp[,2] < (alpha_level/length(pcnorm))
  
  # How many are significant?
  sum(sig_bonf_index)
  
  # What percentage of the assayed probes are significant?
  round(100*sum(sig_bonf_index)/length(sig_bonf_index),2)
  

# .............................................................................

  # calculate q-value for each probe 
  qobj <- qvalue(rawp0)
  summary(qobj)
  
  # Visualize adjusted distribution
  qhist <- hist(qobj$qvalues,
                breaks = seq(0,1,0.1),
                plot = FALSE)
  plot(x = seq(0.1,1,0.1),
       y = qhist$count,
       log="y",
       xlab = "q-value",
       ylab = "Frequency",
       type = "h",
       lwd=10,
       lend=2,
       col="blue")
  
  q_distro_plot <- data.frame(q = qobj$qvalues) %>% 
    ggplot() +
    aes(q)+ 
    geom_histogram(bins = 20,
                   fill = "blue",
                   color = "white",
                   alpha = 0.6) +
    xlab("q-value") +
    ylab("Frequency") +
    scale_y_continuous(trans = log10_trans(),
                       breaks = trans_breaks("log10", function(x) 10^x),
                       labels = trans_format("log10", math_format(10^.x))) +
    theme_light()
  
  q_distro_plot

# .............................................................................

  # Controlling the FDR at 0.1 which probes are significant?
  sig_q_index <- qobj$qvalues < (alpha_level)
  
  # How many are significant?
  sum(sig_q_index)
  
  # What percentage of the assayed probes are significant?
  round(100*sum(sig_q_index)/length(sig_q_index),2)



