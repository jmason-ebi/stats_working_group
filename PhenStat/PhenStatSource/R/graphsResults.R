## Copyright © 2011-2013 EMBL - European Bioinformatics Institute
## 
## Licensed under the Apache License, Version 2.0 (the "License"); 
## you may not use this file except in compliance with the License.  
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##------------------------------------------------------------------------------
## graphsResults.R contains functions for model fit diagnostic plots: 
## qqplotGenotype, plotResidualPredicted, qqplotRandomEffects,
## boxplotResidualBatch, qqplotRotatedResiduals 
##------------------------------------------------------------------------------
## Q-Q plot of residuals for each genotype
qqplotGenotype<-function(phenTestResult){
    
    # Checks
    if(is(phenTestResult,"PhenTestResult")) {
        x <- phenTestResult$model.dataset
        modeloutput <- phenTestResult$model.output
    }
    else{
        stop("Please create a PhenTestResult object first.")
    }
    
    # Plot creation
    res <- resid(modeloutput)
    data_all <- data.frame(x, res)
    a <- levels(data_all$Genotype)
    op <- par(mfrow=c(1,2))     
    Gp1 <- subset(data_all, data_all$Genotype==a[1])
    Gp2 <- subset(data_all, data_all$Genotype==a[2])
    qqnorm(Gp1$res, main=" ")
    qqline(Gp1$res)
    legend("topleft", a[1], cex=1.3, bty="n")
    close.screen(n=1, all.screens = FALSE)
    qqnorm(Gp2$res, main=" ")
    qqline(Gp2$res)
    legend("topleft", a[2], cex=1.3, bty="n")
    par(op)
}

##------------------------------------------------------------------------------
## Predicted versus residual plots split by genotype
plotResidualPredicted<-function(phenTestResult){
    
    # Checks
    if(is(phenTestResult,"PhenTestResult")) {
        x <- phenTestResult$model.dataset
        modeloutput <- phenTestResult$model.output
    }
    else{
        stop("Please create a PhenTestResult object first.")
    }
    
    # Plot creation
    pred <- predict(modeloutput)
    res <- resid(modeloutput)
    data_all <- data.frame(x, res, pred)
    a <- levels(x$Genotype)
    genotype_no <- length(a)
    op <- par(mfrow=c(1,2)) 
    Gp1pred <- subset(data_all, data_all$Genotype==a[1])
    Gp2pred <- subset(data_all, data_all$Genotype==a[2])
    plot(x=Gp1pred$pred, y=Gp1pred$res, xlab="Predicted", ylab="Residuals")
    legend("topleft", a[1], cex=1.3, bty="n")
    plot(x=Gp2pred$pred, y=Gp2pred$res, xlab="Predicted", ylab="Residuals")
    legend("topleft", a[2], cex=1.3, bty="n")
    par(op)
}  


##------------------------------------------------------------------------------
## Q-Q plot of blups
qqplotRandomEffects<-function(phenTestResult){
    
    # Checks
    if(is(phenTestResult,"PhenTestResult")) {
        x <- phenTestResult$model.dataset
        modeloutput <- phenTestResult$model.output
        keep_batch <- phenTestResult$model.effect.batch
    }
    else{
        stop("Please create a PhenTestResult object first.")
    }
    
    # Plot creation
    if(keep_batch){
        blups <- ranef(modeloutput)
        close.screen(n=1, all.screens = FALSE)
        qqnorm(blups[ ,1], main=" ")
        qqline(blups[ ,1])
        
    }
    else {
        message("Diagnostics on random effects not relevant as variation 
                between batches was not significant.")
    }
}

##------------------------------------------------------------------------------
## Residue versus batch split by genotype
boxplotResidualBatch<-function(phenTestResult){
    
    # Checks
    if(is(phenTestResult,"PhenTestResult")) {
        x <- phenTestResult$model.dataset
        modeloutput <- phenTestResult$model.output
    }
    else{
        stop("Please create a PhenTestResult object first.")
    }
    
    if (!('Batch' %in% colnames(x)))
    stop("Batch column is missed in the dataset.")
    
    # Plot creation
    res <- resid(modeloutput)
    data_all <- data.frame(x, res)
    a <- levels(x$Genotype)
    op <- par(mfrow=c(1,2))  
    Gp1 <- subset(data_all, data_all$Genotype==a[1])
    Gp2 <- subset(data_all, data_all$Genotype==a[2])
    with(Gp1, boxplot(res~Batch, ylab="Residuals", xlab="Batch", names=NULL))
    legend("bottomleft", a[1], cex=1.3, bty="n")
    with(Gp2, boxplot(res~Batch, ylab="Residuals", xlab="Batch", names=NULL))
    legend("bottomleft", a[2], cex=1.3, bty="n")   
    par(op)
}

##------------------------------------------------------------------------------
## Q-Q plot of rotated residuals
qqplotRotatedResiduals<-function(phenTestResult){
    
    # Checks
    if(is(phenTestResult,"PhenTestResult")) {
        x <- phenTestResult$model.dataset
        modeloutput <- phenTestResult$model.output
        keep_batch <- phenTestResult$model.effect.batch
    }
    else{
        stop("Please create a PhenTestResult object first.")
    }
    
    # Plot creation
    x[, c("Genotype", "Gender", "Batch")] = lapply(x[, 
                    c("Genotype", "Gender", "Batch")], factor)
    
    if (keep_batch){
        # Extract variance estimates
        sdests <- exp(attr(modeloutput$apVar, "Pars"))        
        # Create random effects design matrix   
        Zbat <- model.matrix(~ Batch, model.frame( ~ Batch, modeloutput$groups))    
        # Create estimated cov(y)
        ycov <- (Zbat %*% t(Zbat)) * sdests["reStruct.Batch"]^2 + 
        diag(rep(1,nrow(modeloutput$groups))) * sdests["lSigma"]^2    
        # Cholesky decomposition of inverse of cov(y) (see Houseman '04 eq. (2))
        Lt <- chol(solve(ycov)) 
        # Unrotated residuals
        unrotres <-  modeloutput$residuals[, "fixed"]    
        # Rotated residuals
        rotres <- Lt %*%  modeloutput$residuals[, "fixed"]           
        # Plot 
        op <- par(mfrow=c(1,2)) 
        qqnorm(unrotres, main = "Unrotated")
        qqline(unrotres)
        qqnorm(rotres, main = "Rotated")
        qqline(rotres)
        par(op)
    }
    else{
        message("Diagnostics on rotated residues not relevant as variation 
                between batches was not significant.")
    }
}

##------------------------------------------------------------------------------
##Stacked bar plot of count data for a variable
categoricalBarplot<-function(phenTestResult){
    
    if(is(phenTestResult,"PhenTestResult")) {
        x <- phenTestResult$model.dataset
        modeloutput <- phenTestResult$model.output
    }
    else{
        stop("Please create a PhenTestResult object first.")
    }
    
    if (!phenTestResult$method=="FE")
    stop("Categorical bar plot can be created only within 
            Fisher Exact Test framework.")
    
    # Produces graphs 
    numberofgenders <- phenTestResult$numberGenders
    # Colors for the plot and legends
    plot_col <- c(1:dim(phenTestResult$model.output$count_matrix_all)[1])
    if(numberofgenders==2){
        
        op <- par(mfrow=c(1,4)) 
        barplot(phenTestResult$model.output$percentage_matrix_all[ ,1:2], 
                main="All data", beside=FALSE, xlab="Genotype", 
                ylab="Percentage", col=plot_col)
        
        barplot(phenTestResult$model.output$percentage_matrix_male[ ,1:2], 
                main="Male animals only", beside=FALSE,  xlab="Genotype", 
                ylab="Percentage", col=plot_col)
        
        barplot(phenTestResult$model.output$percentage_matrix_female[ ,1:2], 
                main="Female animals only", beside=FALSE,  xlab="Genotype", 
                ylab="Percentage", col=plot_col)
        
        plot(1, type = "n", axes=FALSE, xlab="", ylab="")
        legend("topleft", 
                legend = rownames(phenTestResult$model.output$count_matrix_all), 
                fill=plot_col, title="Legend",bty="n")       
        par(op)
    }else{
        op <- par(mfrow=c(1,2))
        barplot(phenTestResult$model.output$percentage_matrix_all[ ,1:2], 
                main="All data", beside=FALSE, xlab="Genotype", 
                ylab="Percentage", col=plot_col)
        
        plot(1, type="n", axes=FALSE, xlab="", ylab="")
        legend("topright", 
                legend = rownames(phenTestResult$model.output$count_matrix_all), 
                fill=plot_col,  title="Legend", bty="n")
        par(op)
    }
    
}
##------------------------------------------------------------------------------