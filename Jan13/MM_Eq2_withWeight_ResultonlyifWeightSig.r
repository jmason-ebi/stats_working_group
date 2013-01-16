#----------------------------------------------------------------------------------------------------
#Function model_Formula:  set the basic fully loaded model formula which depends on how many genders levels exist.
model_Formula <- function(dataset, depVariable){
	numberofgenders=length(levels(dataset$Gender))
	if(numberofgenders==2){
		model.formula <- as.formula(paste(depVariable, "~", paste("Genotype", "Gender", "Genotype*Gender","Weight", sep= "+")))
	}else{ 
		model.formula <- as.formula(paste(depVariable, "~", paste("Genotype", "Weight",  sep= "+"))) 
	} 
	return(model.formula)
}

#---------------------------------------------------------------------------------------------------------------------------
#Function final_genotype_model: testing the fixed effects and building final genotype model formula
# Goal:  to test fixed effects of the model and based on the output build the final genotype model formula for later testing.  As a genotype model it automatically includes genotype.
# First model_forFIXEDtest to build the model to be queried
# The anova function tests the fixed effects associated by treatment with a null hypothesis that the regression coefficients are equal to zero  and an alternative hypothesis that the regression coefficient are not equal to zero.
# If the p-values of these tests are less than 0.05 we reject the null and accept the alternative that the are significant components of the model and should be included.
# Note a complexity surrounds the interaction term  - if it is significant but gender is excluded it is included.


final_genotype_model<-function(dataset, depVariable){
	model_followingbatchandvartest=model_forFIXEDtest(dataset, depVariable)
	anova_results = anova(model_followingbatchandvartest, type="marginal")$"p-value" < 0.05
	numberofgenders=length(levels(dataset$Gender))
	if(numberofgenders==2){
		keepGender = anova_results[3]
		keepWeight = anova_results[4]
		keepInteraction = anova_results[5]
		
		if ((keepGender && keepWeight && keepInteraction)| (!keepGender && keepWeight && keepInteraction)){
			return(model.formula <- as.formula(paste(depVariable, "~", paste("Genotype", "Gender", "Genotype*Gender", "Weight", sep= "+"))))
			
		} else if(keepGender && keepWeight && !keepInteraction){
			return(model.formula <- as.formula(paste(depVariable, "~", paste("Genotype", "Gender", "Weight", sep= "+"))))
			
		} else if(!keepGender && keepWeight && !keepInteraction){
			return(model.formula <- as.formula(paste(depVariable, "~",paste("Genotype", "Weight", sep= "+"))))
		}
	
	}else{
		return(model.formula <- as.formula(paste(depVariable, "~", paste("Genotype", "Weight", sep="+"))))
	}
}

#---------------------------------------------------------------------------------------------------------------------------
#Function final_null_model: testing the fixed effects and building final null model
# Goal:  to test fixed effects of the model and based on the output build the final null model formula for later testing - as a null model it automatically excludes genotype and interaction term.
# First model_forFIXEDtest to build the model to be queried
# The anova function tests the fixed effects associated by treatment with a null hypothesis that the regression coefficients are equal to zero  and an alternative hypothesis that the regression coefficient are not equal to zero.
# If the p-values of these tests are less than 0.05 we reject the null and accept the alternative that the are significant components of the model and should be included.
# If no terms are significant a model can be build with just an intercept element this is specified as  "model.formula <- as.formula(paste(depVariable, "~", "1"))"


final_null_model<-function(dataset, depVariable){
	model_followingbatchandvartest=model_forFIXEDtest(dataset, depVariable)
	anova_results = anova(model_followingbatchandvartest, type="marginal")$"p-value" < 0.05
	numberofgenders=length(levels(dataset$Gender))
	if(numberofgenders==2){
		keepGender = anova_results[3]
	
		if(!keepGender){
			return(model.formula <- as.formula(paste(depVariable, "~", "Weight")))
		
		}else{
			return(model.formula <- as.formula(paste(depVariable, "~", paste("Gender", "Weight", sep= "+"))))
		}
	}else{
			return(model.formula <- as.formula(paste(depVariable, "~", "Weight")))
	}
}


#-------------------------------------------------------------------------------------
#Function: table_content.  function return the table content which indicates where to query the table to grab information but also what can be grabbed.  


table_content<-function(dataset,depVariable){
	model_followingbatchandvartest=model_forFIXEDtest(dataset, depVariable)
	anova_results = anova(model_followingbatchandvartest, type="marginal")$"p-value" < 0.05
	numberofgenders=length(levels(dataset$Gender))
	if(numberofgenders==2){
		keepGender = anova_results[3]
		keepWeight = anova_results[4]
		keepInteraction = anova_results[5]
		return(list(Gender_sig=keepGender, Weight_sig=keepWeight, Interaction_sig=keepInteraction))
	}else{
		keepWeight = anova_results[3]
		return(list(Gender_sig=FALSE, Weight_sig=keepWeight, Interaction_sig=FALSE))
	}
}   
#--------------------------------------------------------------------

#Function: tablelength.  function return the model length which is needed to extract the data correctly.
#Goal of this function is to return a length measure that will determine the table width so when we try to capture the output we can point correctly to the right point in a vector of values.


tablelength<-function(dataset,depVariable){
	model_followingbatchandvartest=model_forFIXEDtest(dataset, depVariable)
	anova_results = anova(model_followingbatchandvartest, type="marginal")$"p-value" < 0.05
	numberofgenders=length(levels(dataset$Gender))
	if(numberofgenders==2){
		keepGender = anova_results[3]
		#here I am counting how many elements will be on the table based on how the model used.  However the model used isnot a direct additive system of the yes calls (ie you can't have an interaction if you don't have gender in the model).
		keepWeight = anova_results[4]
		keepInteraction = anova_results[5]
		
		
		if((keepGender && keepInteraction)|(!keepGender && keepInteraction)){
			return(table_length=5)
		}else if(keepGender && !keepInteraction){
			return(table_length=4)
		}else {
			return(table_length=3)
		}  
	}else{
		return(table_length=3)
	}
}  

#-------------------------------------------------------------------------------------
#Function: finalmodel_info - Capturing the information from the final model

finalmodel_info<-function(dataset, depVariable){
	dataset=EnsureWTisRefLevel(dataset)
	table_content=table_content(dataset, depVariable)
	Gender_sig=table_content$Gender_sig
	Weight_sig=table_content$Weight_sig
	Interaction_sig=table_content$Interaction_sig
	MM_fitquality=Diagnostictest(dataset, depVariable)
	
	if(!Weight_sig){
		
		#If weight is not significant then the output is the same as fitting model Eq1 and so no output is needed. 
		genotype_estimate = "NA"
		genotype_estimate_SE = "NA"
		genotype_p_value =  "NA"
		weight_estimate="NA"
		weight_estimate_SE="NA"
		weight_p_value="NA"
		interaction_estimate="NA"
		interaction_estimate_SE="NA"
		interaction_p_value="NA"
		intercept_estimate = "NA"
		intercept_estimate_SE = "NA"
		gender_estimate="NA"
		gender_estimate_SE="NA"
		gender_p_value= "NA"
		variance_test="NA"
		Nulltest_genotype_pvalue="NA"
		keep_batch="NA"
		values=c("Eq2", depVariable, keep_batch, variance_test, Nulltest_genotype_pvalue, genotype_estimate, genotype_estimate_SE,  genotype_p_value,gender_estimate, gender_estimate_SE,  gender_p_value, interaction_estimate, interaction_estimate_SE, interaction_p_value, weight_estimate, weight_estimate_SE, weight_p_value, MM_fitquality, intercept_estimate, intercept_estimate_SE)
		return(values)
	
	}else{
	
		keep_batch=testing_batch(dataset,depVariable)	
		variance_test=testing_variance(dataset, depVariable)
		Nulltest_genotype_pvalue=testing_genotype_effect(dataset,depVariable)
		
		modeloutput=summary(finalmodel(dataset, depVariable))
		lengthoftable=tablelength(dataset,depVariable)	
		
		#problem depending on the length of the table where we grab values.  the table is organised as a vector of values,  ordered going down each column in the summary table.  there is one less column when batch is not significant.
	
		if(keep_batch){
			
			#for mixed model 
			intercept_estimate = modeloutput[["tTable"]][[1]]
			intercept_estimate_SE = modeloutput[["tTable"]][[(1+lengthoftable)]]
			genotype_estimate = modeloutput[["tTable"]][[2]]
			genotype_estimate_SE = modeloutput[["tTable"]][[(2+lengthoftable)]]
			genotype_p_value =  modeloutput[["tTable"]][[(2+4*lengthoftable)]]
			
			if((Weight_sig && Gender_sig && Interaction_sig) | (Weight_sig && !Gender_sig&& Interaction_sig)){
				weight_estimate=modeloutput[["tTable"]][[4]]
				weight_estimate_SE=modeloutput[["tTable"]][[(4+lengthoftable)]]
				weight_p_value=modeloutput[["tTable"]][[(4+4*lengthoftable)]]	
				interaction_estimate=modeloutput[["tTable"]][[5]]
				interaction_estimate_SE=modeloutput[["tTable"]][[(5+lengthoftable)]]
				interaction_p_value=modeloutput[["tTable"]][[(5+4*lengthoftable)]]
				gender_estimate=modeloutput[["tTable"]][[3]]
				gender_estimate_SE=modeloutput[["tTable"]][[(3+lengthoftable)]]
				gender_p_value= modeloutput[["tTable"]][[(3+4*lengthoftable)]]
		
			} else if (Weight_sig && !Gender_sig && !Interaction_sig){	
				weight_estimate=modeloutput[["tTable"]][[3]]
				weight_estimate_SE=modeloutput[["tTable"]][[(3+lengthoftable)]]
				weight_p_value=modeloutput[["tTable"]][[(3+4*lengthoftable)]]
				interaction_estimate="NA"
				interaction_estimate_SE="NA"
				interaction_p_value="NA"
				gender_estimate="NA"
				gender_estimate_SE="NA"
				gender_p_value="NA"
			
			}else if (Weight_sig && Gender_sig && !Interaction_sig){
				weight_estimate=modeloutput[["tTable"]][[4]]
				weight_estimate_SE=modeloutput[["tTable"]][[(4+lengthoftable)]]
				weight_p_value=modeloutput[["tTable"]][[(4+4*lengthoftable)]]
				interaction_estimate="NA"
				interaction_estimate_SE="NA"
				interaction_p_value="NA"
				gender_estimate=modeloutput[["tTable"]][[3]]
				gender_estimate_SE=modeloutput[["tTable"]][[(3+lengthoftable)]]
				gender_p_value= modeloutput[["tTable"]][[(3+4*lengthoftable)]]				
			
			}
				
		values=c("Eq2", depVariable, keep_batch, variance_test, Nulltest_genotype_pvalue, genotype_estimate, genotype_estimate_SE,  genotype_p_value,gender_estimate, gender_estimate_SE,  gender_p_value, interaction_estimate, interaction_estimate_SE, interaction_p_value, weight_estimate, weight_estimate_SE, weight_p_value, MM_fitquality, intercept_estimate, intercept_estimate_SE)
		
		return(values)
		
		}else{
		#adaption for being a linear model rather than a mixed model
			intercept_estimate = modeloutput[["tTable"]][[1]]
			intercept_estimate_SE = modeloutput[["tTable"]][[(1+lengthoftable)]]
			genotype_estimate = modeloutput[["tTable"]][[2]]
			genotype_estimate_SE = modeloutput[["tTable"]][[(2+lengthoftable)]]
			genotype_p_value =  modeloutput[["tTable"]][[(2+3*lengthoftable)]]
		
			if((Weight_sig && Gender_sig && Interaction_sig )|(Weight_sig && !Gender_sig&& Interaction_sig)){
				weight_estimate=modeloutput[["tTable"]][[4]]
				weight_estimate_SE=modeloutput[["tTable"]][[(4+lengthoftable)]]
				weight_p_value=modeloutput[["tTable"]][[(4+3*lengthoftable)]]	
				interaction_estimate=modeloutput[["tTable"]][[5]]
				interaction_estimate_SE=modeloutput[["tTable"]][[(5+lengthoftable)]]
				interaction_p_value=modeloutput[["tTable"]][[(5+3*lengthoftable)]]
				gender_estimate=modeloutput[["tTable"]][[3]]
				gender_estimate_SE=modeloutput[["tTable"]][[(3+lengthoftable)]]
				gender_p_value= modeloutput[["tTable"]][[(3+3*lengthoftable)]]
				
			} else if (Weight_sig && Gender_sig && !Interaction_sig){
					weight_estimate=modeloutput[["tTable"]][[4]]
					weight_estimate_SE=modeloutput[["tTable"]][[(4+lengthoftable)]]
					weight_p_value=modeloutput[["tTable"]][[(4+3*lengthoftable)]]
					interaction_estimate="NA"
					interaction_estimate_SE="NA"
					interaction_p_value="NA"
					gender_estimate=modeloutput[["tTable"]][[3]]
					gender_estimate_SE=modeloutput[["tTable"]][[(3+lengthoftable)]]
					gender_p_value= modeloutput[["tTable"]][[(3+3*lengthoftable)]]
					
			}else if (Weight_sig && !Gender_sig && !Interaction_sig){	
				weight_estimate=modeloutput[["tTable"]][[3]]
				weight_estimate_SE=modeloutput[["tTable"]][[(3+lengthoftable)]]
				weight_p_value=modeloutput[["tTable"]][[(3+3*lengthoftable)]]
				interaction_estimate="NA"
				interaction_estimate_SE="NA"
				interaction_p_value="NA"
				gender_estimate="NA"
				gender_estimate_SE="NA"
				gender_p_value="NA"
			}	
			values=c("Eq2", depVariable, keep_batch, variance_test, Nulltest_genotype_pvalue, genotype_estimate, genotype_estimate_SE,  genotype_p_value,gender_estimate, gender_estimate_SE,  gender_p_value, interaction_estimate, interaction_estimate_SE, interaction_p_value, weight_estimate, weight_estimate_SE, weight_p_value, MM_fitquality, intercept_estimate, intercept_estimate_SE)
			return(values)
		}  	
		
	}
}	
	
	
########################################################	
#Function: Diagnostictest - Diagnostic test output for MM quality of fit

Diagnostictest<-function(dataset, depVariable){
	table_content=table_content(dataset, depVariable)
	Weight_sig=table_content$Weight_sig
	a=levels(dataset$Genotype)
	
	if(!Weight_sig){
		testresults=c(a[1], "NA", a[2], "NA", "NA", "NA")
		return(testresults)    
	
	}else{	
		
		require(nortest)
		modeloutput=finalmodel(dataset,depVariable)
		res=resid(modeloutput)
		data_all= data.frame(dataset, res)
		a=levels(data_all$Genotype)
		genotype_no=length(a)
		keep_batch=testing_batch(dataset,depVariable)
		data_all[, c("Gender", "Assay.Date")] = lapply(data_all[, c("Gender", "Assay.Date")], factor)
		No_batches=nlevels(data_all$Assay.Date)
		outputnumeric=is.numeric(modeloutput$apVar)
						
		if(keep_batch && No_batches >7 && outputnumeric){
			blups=ranef(modeloutput)
			blups_test= cvm.test(blups [ ,1])$p.value
			sdests = exp(attr(modeloutput$apVar, "Pars"))           #extract variance estimates
			Zbat = model.matrix(~ Assay.Date, model.frame( ~ Assay.Date, modeloutput$groups))    #create random effects design matrix
			ycov = (Zbat %*% t(Zbat)) * sdests["reStruct.Assay.Date"]^2 + diag(rep(1,nrow(modeloutput$groups))) * sdests["lSigma"]^2    #create estimated cov(y)
			Lt = chol(solve(ycov))  #Cholesky decomposition of inverse of cov(y) (see Houseman '04 eq. (2))
			rotres = Lt %*%  modeloutput$residuals[, "fixed"]    #rotated residuals
			rotated_residual_test=cvm.test(rotres)$p.value
		}else{
			blups_test="NA"
			rotated_residual_test="NA"
		}   
		
		Gp1 = subset(data_all, Genotype==a[1])
		Gp2 = subset(data_all, Genotype==a[2])
		No_Gp1=countDataPoints(Gp1, depVariable)
		No_Gp2=countDataPoints(Gp2, depVariable)
		
		if(No_Gp1>7){
			gp1_norm_res= cvm.test(Gp1$res)$p.value
		}else{
			gp1_norm_res= "NA"
		}	
		
		if(No_Gp2>7){
			gp2_norm_res= cvm.test(Gp2$res)$p.value
		}else{
			gp2_norm_res= "NA"
		}	
		
		testresults=c(a[1], gp1_norm_res, a[2], gp2_norm_res, blups_test, rotated_residual_test)
		return(testresults)        
	
	}
		
}
