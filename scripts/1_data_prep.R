##############################################################################
#                          STAT 465 FINAL PROJECT
#
#                             Data Preparation 
#
#                                Stan Szydlo
##############################################################################

# Load Packages ..............................................................

  # getwd()
  setwd("/Users/stan/Desktop/stat465/Depression Biomarker Project")
  
  # source("http://bioconductor.org/biocLite.R")
  # BiocManager::install("GEOquery")
  # BiocManager::install("affy")
  # BiocManager::install("hgu133plus2.db", version = "3.8")
  
  library(hgu133plus2.db)
  library(tidyverse)
  library(GEOquery)
  library(affy)
  library(CRAmisc)
  library(ggplot2)
  library(magrittr)


# Load Data ....................................................................

  # Download & unzip raw microarray data from GEO
  getGEOSuppFiles("GSE98793")

  untar("GSE98793/GSE98793_RAW.tar", 
        exdir = "GSE98793/GSE98793_RAW")

  datadir = "GSE98793/GSE98793_RAW_unzipped"
  dir.create(datadir)
  
  unzip_dir("GSE98793/GSE98793_RAW",
            out_dir = datadir,
            ext = "gz")

  
  # Download GSM from GEO
  GEOset <- getGEO("GSE98793",
         destdir = "GSE98793",
         GSEMatrix = TRUE)
  
  GEOset <- GEOset[[1]]
  
  
  # Load raw microarray data
  fnames <- dir(path=datadir, pattern=".CEL")
  pcraw <- ReadAffy(filenames=fnames, celfile.path=datadir)
  
  # Clean column names 
  reference_ID <- GEOset$geo_accession
  sampleNames(pcraw) <- reference_ID


# Annotate Data ..........................................................

  # http://biolearnr.blogspot.com/2017/05/bfx-clinic-getting-up-to-date.html
  
  collapser <- function(x){
    x %>% unique %>% sort %>% paste(collapse = "|")
  }
  
  annots <- AnnotationDbi::select(
    x       = hgu133plus2.db,
    keys    = rownames(pcraw),
    columns = c("PROBEID", "ENSEMBL", "ENTREZID", "SYMBOL"),
    keytype = "PROBEID"
  ) %>%
    group_by(PROBEID) %>%
    summarise_each(funs(collapser)) %>%
    ungroup
  
  fd <- new("AnnotatedDataFrame",
            data = data.frame(annots[, -1], stringsAsFactors = FALSE)
  )
  rownames(fd) <- annots$PROBEID
  featureData(GEOset) <- fd
  
  # data.frame(PROBEID = annots$PROBEID, SYMBOL = annots$SYMBOL) %>% 
  # write_csv("data/probes_genes.csv")
  

# Clean Data ......................................................

  gene_symbol <- GEOset@featureData@data$SYMBOL
  age <- GEOset$`age:ch1`
  anxiety <- (GEOset$`anxiety:ch1`=='yes')
  batch <- GEOset$`batch:ch1`
  gender <- GEOset$`gender:ch1`
  mdd <- (GEOset$`subject group:ch1` == "CASE; major depressive disorder (MDD) patient")
  
  # Define new class for future analysis 
  group <- c()
  for (i in c(1:length(reference_ID)) ){
    group[i] <- case_when(
      !mdd[i] && !anxiety[i] ~ 0, # CNTRL (no anxiety)
      mdd[i]  &&  !anxiety[i] ~ 1, # MDD (no anxiety)
      mdd[i]  &&  anxiety[i] ~ 2, # MDD with Anxiety
      !mdd[i]  &&  anxiety[i] ~ 3 # CNTRL with Anxiety
    )
  }


# Visualize Raw Data ......................................................

  colors <- sapply(group, 
                   function(x){ case_when(
                                x == 0 ~ "green",
                                x == 1 ~ "blue",
                                x == 2 ~ "red")
                     }
  )
  
  # visualize distribution of raw expression values for each patient
  pcraw_plot <- boxplot(pcraw,
          col = colors,
          main = "Raw Distributions",
          ylab = "Expression",
          xlab = "Participant",
          xaxt="n")
  legend(x = "topleft", legend=c("CNTL", "MDD", "MDD + Anxiety"),
         fill=c("green", "blue", "red"))

  
# Quantile Normalization ....................................................

  # pcnorm <- rma(pcraw)  # robust microarray average
  # write.exprs(pcnorm,"data/GSE98793_norm.txt")


# Visualize Normalized Data ..................................................

  pcnorm <- read.table( "data/GSE98793_norm.txt" )
  
  pcnorm_plot <- boxplot(pcnorm,
          col = colors,
          main = "Normalized Distributions", 
          ylab = "Expression",
          xlab = "Participant",
          xaxt="n")
  legend(x = "topleft", legend=c("CNTL", "MDD", "MDD + Anxiety"),
         fill=c("green", "blue", "red"))
  
  pcnorm_dens_plot <- plotDensity(pcnorm, main = "Normalized Density Plot", col = 1:3, xlab = "log(intensity)")


# Clean Data ...................................................................

  clean_pcnorm <- data.frame(reference_ID,
                        batch,
                        age,
                        gender,
                        anxiety, 
                        mdd,
                        group,
                        t(pcnorm) ) # transpose pcnorm data 
  
  colnames(clean_pcnorm) <- c("reference_ID",
                             "batch",
                              "age",
                              "gender",
                              "anxiety", 
                              "mdd",
                              "group",
                              annots$PROBEID)
  
  # write_csv(clean_pcnorm,"data/clean_data.csv")  # output the model-ready data to local hard drive.
  # write_csv(clean_pcnorm[,1:7],"data/clean_demog_data.csv")



