rm(list=ls(all=TRUE))
library(devtools)
devtools::unload("rqPen")
install_github("bssherwood/rqpen")
library(rqPen)


predict.models <- function(object, newx){
	cbind(1,newx) %*% object$coefficients
}

predict.errors <- function(object, newx, newy){
	preds <- predict(object,newx)
	errors <- lapply(preds,subtract,newy)
}

check.errors <- function(object,newx,newy){
	lapply(object$models,check.errors.model,newx,newy)
}

check.errors.model <- function(object,newx,newy){
	preds <- predict.models(object,newx)
	errors <- newy- preds
	check(errors,object$tau)
}

predict.rq.pen.seq <- function(object, newx){
	lapply(object$models, predict.models,newx=newx)
}

subtract <- function(predicted,obs){
	obs-predicted
}

modelTau <- function(object){
	object$tau
}

modelA <- function(object){
	object$a	
}




byTauResults <- function(cvErr,tauvals,avals,models,se){
#for loops!
	mn <- length(tauvals)
	overallMin <- apply(cvErr,1,min)
	overallSpot <- apply(cvErr,1,which.min)
	index <- 1:mn
	
	btr <- data.table(tau=tauvals,minCv=overallMin,lamdaIndex=overallSpot,a=avals,modelsIndex=index)
	btr <- btr[, .SD[which.min(minCv)],by=tau]
	lambdaVals <- lambda[btr[[3]]]
	
	cvse <- lambda1se <- lambda1seIndex <- lambdaVals <-  NULL
	for(i in 1:nrow(btr)){
		subse <- se[btr[[5]][i],btr[[3]][i]] #5 is model index and 3 is lambda index
		cvse <- c(cvse,subse)
		se1Above <- btr[[2]][1] + subse
		subLambda <- models[[btr[[5]]][i]]$lambda[btr[[3]][i]]
		subLambda1sePos <- which(cvErr[btr[[5]][1],] <= se1Above)[1]
		lambda1seIndex <- c(lambda1seIndex,subLambda1sePos)
		subLambda1se <- lambda[subLambda1sePos]
		lambda1se <- c(lambda1se,subLambda1se)
	}
	
	btr <- cbind(btr, lambda=lambdaVals, cvse = cvse, lambda1se=lambda1se, lambda1seIndex=lambda1seIndex)
	btr <- setcolorder(btr, c(1,2,6,3,8,9,4,7,5))
	btr
}


x <- matrix(rnorm(8000),ncol=8)
y <- 1 + 3*x[,1] + 2*x[,3] - 5*x[,8] + rt(1000,5)
tau <- c(.2,.5)
lambda=NULL
weights=NULL
penalty=c("LASSO","ridge","enet","aLASSO","SCAD","MCP")[5]
a=c(3,4)
cvFunc=NULL
nfolds=10
foldid=NULL
nlambda=100
groupError=TRUE
cvSummary=mean
tauWeights=rep(1,length(tau))


#cv.rq.pen <- function(x,y,tau=.5,lambda=NULL,weights=NULL,penalty=c("LASSO","ridge","enet","aLASSO","SCAD","MCP"),a=NULL,cvFunc=NULL,nfolds=10,foldid=NULL,nlambda=100,groupError=TRUE,cvSummary=mean,tauWeights=rep(1,length(tau)),...){
#need to think about how to handle this for multi vs one tau. Also multi-a vs single a. Do the four types or something like that and then run the code
	n <- length(y)
	if(is.null(weights)==FALSE){
		stop("weights not currently implemented. Can use cv.rq.pen.old, but it supports fewer penalties and is slower.")
	}
	if(is.null(foldid)){
      foldid <- randomly_assign(n,nfolds)
    }
	fit <- rq.pen(x,y,tau,lambda=lambda,penalty=penalty,a=a)#,...)
	if(!groupError){
		indErrors <- vector(mode="list",length=nfolds)
	}
	nt <- length(tau)
	na <- length(fit$a)
	nl <- length(fit$models[[1]]$lambda)
	foldErrors <- fe2ndMoment <- matrix(rep(0,nt*na*nl),ncol=nl)
    for(i in 1:nfolds){
		train_x <- x[foldid!=i,]
		train_y <- y[foldid!=i]
		test_x <- x[foldid==i,,drop=FALSE]
		test_y <- y[foldid==i]
		trainModel <- rq.pen(train_x,train_y,tau,lambda=fit$lambda,penalty=penalty,a=fit$a)#,...)
		if(is.null(cvFunc)){
			testErrors <- check.errors(trainModel,train_x,train_y)
		} else{
			testErrors <- lapply(predict.errors(trainModel,test_x,test_y),cvFunc)
		}
		if(!groupError){
			indErrors[[i]] <- testErrors # will this be a problem? A list of a list? 
		}
		foldMeans <- do.call(rbind, lapply(testErrors,apply,2,cvSummary))
		foldErrors <- foldErrors + foldMeans
		fe2ndMoment <- fe2ndMoment + foldMeans^2
    }
	fe2ndMoment <- fe2ndMoment/nfolds
	foldErrors <- foldErrors/nfolds
	stdErr <- sqrt( (nfolds/(nfolds-1))*(fe2ndMoment - foldErrors^2))
	tauvals <- sapply(fit$models,modelTau)
	avals <- sapply(fit$models,modelA)
	btr <- byTauResults(foldErrors,tauvals,avals,fit$models,se)
}
#}




