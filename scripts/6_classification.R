##############################################################################
#                           STAT 465 FINAL PROJECT
#
#                           Patient Classification: 
#                   Train predictive models to distinguish 
#              clinically depressed patients from healthy controls.
#
#                                 Stan Szydlo
##############################################################################

# Load Packages & Data .......................................................

  library(tidyverse)
  library(ggplot2)
  library(randomForest)
  library(xgboost)
  library(glmnet)
  library(e1071)
  
  data_q <- data.frame(read_csv("data/data_q.csv"))
  
  data <- data_q %>% dplyr::select(mdd, c(5:ncol(data_q))) 

# Classification ..............................................................
  
  set.seed(24)
  
  zeroR_results <- c()
  lasso_results <- c()
  rf_results <- c()
  svm_results <- c()
  xgb_results <- c()
  
  trials = 100
  
for (i in 1:trials){ # validation trials
    
    print(paste("Validation Trial", i))
    
    # split data into training and validation sets
    sample <- sample.int(n = nrow(data),
                         size = floor(.70*nrow(data)),
                         replace = F)
    train_data <- data[sample, ] 
    test_data  <- data[-sample, ] 
    
    # ZeroR ------------------------------------------------------------
    zeroR_pred_success <- sum((test_data$mdd) / nrow(test_data))
    
    zeroR_results <- c(zeroR_results, zeroR_pred_success)
    
    # Lasso Logistic Regression -----------------------------------------
    lasso_fit <- cv.glmnet(x = model.matrix(mdd ~ ., train_data),
                           y = (train_data$mdd),
                           alpha = 1,
                           family = "binomial")
    
    lambda_min <- lasso_fit$lambda.min
    lasso_pred <- predict(lasso_fit,
                          newx = model.matrix(~ . -mdd, data = test_data),
                          s = lambda_min)
    
    lasso_pred_bool <- (lasso_pred > 0.5)
    lasso_pred_result <- lasso_pred_bool==(test_data$mdd)
    lasso_pred_success <- sum(lasso_pred_result)/length(lasso_pred_result)
    
    lasso_results <- c(lasso_results, lasso_pred_success)
    
    # Support Vector Machine ----------------------------------------
    svm_fit <- svm(mdd ~ ., 
                   train_data, 
                   kernel = "linear",
                   type = 'C-classification')
    
    svm_pred <- predict(svm_fit, test_data)
    svm_pred_result <- (svm_pred == test_data$mdd)
    svm_pred_success <- sum(svm_pred_result)/length(svm_pred_result)
    
    svm_results <- c(svm_results, svm_pred_success)
    
    # Stochastic Gradient Boosting --------------------------------
    
    xgb_fit <- xgboost(data = as.matrix(train_data[,-1]),
                               label = (train_data$mdd),
                               max.depth = 6,
                               eta = 0.1, # learning rate
                               nthread = 2,
                               nrounds = 100,
                               objective = "binary:logistic",
                               verbose = 0)
    
    xgb_pred_prob <- predict(xgb_fit[[1]], as.matrix(test_data[,-1]))
    xgb_pred_bool <- as.numeric(xgb_pred_prob > 0.5)
    xgb_pred_result <- xgb_pred_bool==(test_data$mdd)
    xgb_pred_success <- sum(xgb_pred_result)/length(xgb_pred_result)
    
    xgb_results <- c(xgb_results, xgb_pred_success)
    
    # Random Forest ---------------------------------------------------
    train_data$mdd <- factor(train_data$mdd)
    rf_fit <- randomForest(mdd ~ .,
                           data = train_data,
                           ntree = 500,
                           type = classification)
    
    rf_pred <- predict(rf_fit, newdata=test_data) # predict diagnoses
    rf_cm <- table(rf_pred, test_data$mdd) # confusion matrix (actual x predicted)
    rf_pred_success <- (sum(diag(rf_cm)))/sum(rf_cm)
    
    rf_results <- c(rf_results, rf_pred_success)
    
}
  
  
# Visualization ...............................................................
  
  results_df <- data.frame(Lasso = lasso_results, 
                           RF = rf_results, 
                           SVM = svm_results,
                           XGB = xgb_results,
                           ZeroR = zeroR_results) 
  
  
  results <- results_df %>% 
    gather(c('SVM', 
             'Lasso',
             'RF',
             'XGB',
             'ZeroR'),
           key = "Classifier",
           value = "Success")
  
  
  results$Classifier <- factor(results$Classifier,
                               levels = c('SVM',
                                          'Lasso',
                                          'RF',
                                          'XGB', 
                                          'ZeroR'),
                               ordered = TRUE)
  
  
  zeroR_success <- median(zeroR_results)
  
  classifier_plot <- results %>% group_by(Classifier) %>% 
    ggplot(aes(x=Classifier, y=Success)) +
    geom_jitter(alpha = 0.075, color = "blue") +
    geom_boxplot(alpha = 0.7, outlier.shape = 8) + 
    geom_hline(yintercept=zeroR_success, linetype="dashed", color = "red") +
    scale_y_continuous(breaks=c(seq(round(zeroR_success-0.2, 1), 1, 0.05))) +
    coord_flip() +
    theme_light()  
  
  classifier_plot
  
  
# Significance Tests ...........................................................
  
  # Calculate t-statistics assuming unequal variance
  t_svm <- t.test(x = svm_results, y = zeroR_results, alternative = "greater")
  t_lasso <- t.test(x = lasso_results, y = zeroR_results, alternative = "greater")
  t_rf <- t.test(x = rf_results, y = zeroR_results, alternative = "greater")
  t_xgb <- t.test(x = xgb_results, y = zeroR_results, alternative = "greater")

  t_svm$p.value
  t_lasso$p.value
  t_rf$p.value
  t_xgb$p.value
  
















