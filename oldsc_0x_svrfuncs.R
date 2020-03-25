#!/usr/bin/env Rscript
library("dplyr",lib="/home/bct16/Rpackages/3.5")
#
########################
##############################################################
###svm####
library("e1071",lib="/home/bct16/Rpackages/3.5")
library("Morpho",lib="/home/bct16/Rpackages/3.5")
library("parallel",lib="/home/bct16/Rpackages/3.5")
####error functions########
rmse_function <- function(error){
  rmse<-sqrt(mean(error^2))
   return(rmse)
}

rsquared_function<-function(origdata,error){
rsquared<-1-(sum(error^2))/(sum((origdata-mean(origdata))^2))
return(rsquared)
}

###tuning feature selction functions#####
SVRtuning_kfold_parallel<-function(tunedf,y,k,tunecores=NULL,epsilon=seq(.1,1,.1),cost=c(.01,.1,1,10,100,1000,10000)){
#df should be training data
#y is outcome variable to be predicted
#xcols columns to do predicting
#cores number of jobs (default is k)
#k n folds for tuning 
#epsiolon and cost sequences for grid search
require(foreach)
require(doParallel)
require(caret)
require(e1071)
if (is.null(tunecores)){tunecores=k}
registerDoParallel(cores=tunecores)
curd<-tunedf[complete.cases(tunedf),]
fold<-caret::createFolds(1:nrow(curd), k = k,list = FALSE)
params<-expand.grid(cost=cost,epsilon=epsilon)
fml<-as.formula(as.formula(paste0(y,"~.")))
result <- foreach(i = 1:nrow(params), .combine = rbind) %do% {
  c <- params[i, ]$cost
  e <- params[i, ]$epsilon
  ### K-FOLD VALIDATION ###
  #print(i)
  out <- foreach(j = 1:max(fold), .combine = rbind, .inorder = FALSE) %dopar% {
   #print(j)
   deve <- curd[fold != j, ]
    test <- curd[fold == j, ]
    mdl <- e1071::svm(fml, data = deve,kernel = "linear", cost = c, epsilon = e)
    pred <- predict(mdl,test)
    rmse_current<-rmse_function(test[,y]-pred)
    rsquared_current<-rsquared_function(test[,y],test[,y]-pred)
    data.frame(fold=j,rmse=rmse_current,rsq=rsquared_current)
  }
data.frame(c=c,e=e,meanrmse=mean(out$rmse),meanrsq=mean(out$rsq))
}
bestparameters<-result[result$meanrmse==min(result$meanrmse),]
bestparameters$rank<-(bestparameters$c==1)+(bestparameters$e==.1)
bestparameters<-bestparameters[which.max(bestparameters$rank),]

return(bestparameters)
}
#########
svr.unifeatselect<-function(train,y,nfeatures,featselectcores=1){
featurecorrs<-lapply(names(train)[names(train)!=y],function(ename){
var<-c(ename,cor(train[,ename],train[,y]))
})
featurecorrs<-data.frame(do.call(rbind,featurecorrs))
featurecorrs[,2]<-as.numeric(as.character(featurecorrs[,2]))
featurecorrs_r<-featurecorrs[rev(base::order(abs(featurecorrs[,2]))),]
returnfeatures<-as.character(featurecorrs_r[1:nfeatures,1])
return(returnfeatures)
}

svr.pca.featreduction<-function(train,y,propvarretain,scale,center){
trainforpca<-train[,names(train)!=y]
require(Morpho)
if (scale){
trainforpca <- scale(trainforpca)
}
pcaout<-prcompfast(trainforpca,retx=TRUE,center=center,scale.=scale)
prcomp.varex <-  pcaout$sdev^2/sum(pcaout$sdev^2)
prcomp.cumsum <-  cumsum(prcomp.varex)
compiatthreshold <- which.min(prcomp.cumsum <= propvarretain)
pcascoresreturn<-data.frame(pcaout$x[,1:compiatthreshold])
pcaoutlist<-list(pcascoresreturn,pcaout)
return(pcaoutlist)
}


svrtunefeatselectpca<-function(p=NA,train,y,unifeatselect,nfeatures,PCA,propvarretain,tune,tunefolds){
print(p)
featselectednames<-NA
if (unifeatselect){
   featselectednames<-svr.unifeatselect(train,y,nfeatures=nfeatures,featselectcores=tunecores)
}
PCAreturn<-NA
if (PCA){
   PCAreturn<-svr.pca.featreduction(train,y,propvarretain=propvarretain,scale=FALSE,center=TRUE)
}

bestparams<-NA
if (tune){
	tc<-tune.control(sampling="cross",cross=tunefolds)
	tunedsvm<-e1071::tune(svm,as.formula(paste0(y,"~.")),kernel="linear",data=t,ranges=list(epsilon=seq(.1,1,.2),cost=c(.01,.1,1,10,100)),tunecontrol=tc)
	bestparams<-tunedsvm$best.parameters
}

tunefeatselectoutlist<-list(p=p,featselectednames=featselectednames,PCAreturn=PCAreturn,bestparams=bestparams)
return(tunefeatselectoutlist)
}

######SVR single model functions############
svr.single <- function(foldname=NA,test,train,y,tune=T,tunefolds,tunecores,weights=T) {
#foldname, string | number for naming output 
#test, test df
#train, train df
#y, yvarname
#tune, T/F to Tune via SVRtuning_kfold_parallel
#tunefolds, N folds for tuning (tuning occurs on train only)
#weights, T/F to include SVR weights in output
require(e1071)
print(foldname)
 svmmodel<-svm(as.formula(paste0(y,"~.")),kernel="linear",data=train)
 if (tune){
   bestparameters<-SVRtuning_kfold_parallel(tunedf=train,y=y,k=tunefolds,tunecores=tunecores)   
   svmmodel<-svm(as.formula(paste0(y,"~.")),cost=bestparameters$c,epsilon=bestparameters$e,kernel="linear",data=train)
 }
nw<-length(grep("vx",names(train)))
w <-rep(NA,nw)
if (weights){
w <- t(svmmodel$coefs) %*%svmmodel$SV 
}
 
 ####save model performance
 pred_train        <-predict(svmmodel,train)
 pred_test         <-predict(svmmodel,test)

 ######save model params
 
cvout<-as.data.frame(cbind(
   foldname     = foldname,
   cvpred   = pred_test,
   testyval = test[,y],
   traincor = cor(pred_train,train[,y]),
   kernel =svmmodel$kernel,
   epsilon=svmmodel$epsilon,
   cost   =svmmodel$cost,
   gamma  =svmmodel$gamma
 ))
savelist<-list(cvout,w)
return(savelist)
}

svr.trainonly <- function(foldname=NA,train,y,tune=F,tunefolds,tunecores,unifeatselect,nfeatures,PCA,propvarretain,weights=T,featlist) {
#foldname, string | number for naming output
#test, test df
#train, train df
#y, yvarname
#tune, T/F to Tune via SVRtuning_kfold_parallel
#tunefolds, N folds for tuning (tuning occurs on train only)
#weights, T/F to include SVR weights in output
require(e1071)
print(foldname)
featselectednames<-NA
if (unifeatselect){
  	featselectednames<-featlist$featselectednames
   train<-train[,c(featselectednames,y)]  
}
pcamodel<-NA
if (PCA){
   PCAreturn<-featlist$PCAreturn
   train<-cbind(PCAreturn[[1]],data.frame(y=train[,y]))
   names(train)[names(train)=="y"]<-y
   pcamodel<-PCAreturn[[2]]
}

#print("features in train")
#print(length(which(names(train)!=y)))
#print("first 10 feature names")
#print(names(train)[names(train)!=y][1:10])

   if (tune){
	print("using hyperparameters from tuning")
   bestparameters<-featlist$bestparams
   svmmodel<-svm(as.formula(paste0(y,"~.")),cost=bestparameters$cost,epsilon=bestparameters$epsilon,kernel="linear",data=train)
 }else{
	print("using defaualt hyperparameters")
   svmmodel<-svm(as.formula(paste0(y,"~.")),kernel="linear",data=train)
   }
nw<-length(which(names(train)!=y))
w <-rep(NA,nw)
if (weights){
w <- t(svmmodel$coefs) %*%svmmodel$SV
}

 ####save model performance
 pred_train        <-predict(svmmodel,train)
 ######save model params

cvout<-as.data.frame(cbind(
   foldname     = foldname,
   traincor = cor(pred_train,train[,y]),
   kernel =svmmodel$kernel,
   epsilon=svmmodel$epsilon,
   cost   =svmmodel$cost,
   gamma  =svmmodel$gamma
 ))
train<-NULL
savelist<-list(cvout=cvout,svmmodel=svmmodel,svmweights=w,featselectednames=featselectednames,pcamodel=pcamodel)
return(savelist)
}

####svr validation functions#####

SVR_crossvalidation<-function(foldvar,df,y,xcols,verb=FALSE,tune=TRUE,tunefolds,permute=FALSE,yperm=NULL,outerfoldcores,tunecores,weights=FALSE){  
   df<-df[!(is.na(df[,y])),]
   ytrain<-y
   if (permute){
   ytrain<-yperm   
   }

   ####just data for current models#######
   jdcolstrain<-c(ytrain,xcols)
   jddatatrain<-df[,jdcolstrain]
   
   jdcolstest<-c(y,xcols)
   jddatatest<-df[,jdcolstest]
   
   names(jddatatest)[names(jddatatest)==y]<-ytrain   
   folds=df[,foldvar]

   #####
   print(length(unique(folds)))
   print("outer folds")
   if (tune){
   print(tunefolds)
   print("tuning folds")
   }
   #######leave one out loop##############
   outlist <- mclapply(unique(folds),mc.cores=outerfoldcores, function(lo){ 
                          svr.single(foldname=unique(df[df[,foldvar]==lo,foldvar]),test=jddatatest[folds==lo,],train=jddatatrain[folds!=lo,],y=ytrain,tune=tune,tunefolds=tunefolds,tunecores=tunecores,weights=weights)})  

   #####will help embedded list###
   modelfitouts<-lapply(outlist,"[[",1) 
   
   # list apparently needs a name
   #names(modelfitouts) <- unlist(lapply(modelfitouts,function(x) x[1]))
   # make into a outdf
   modeloutdf <- lapply(modelfitouts,function(x) { as.data.frame(x) } ) %>% bind_rows
   #########weights#############
   weightouts<-lapply(outlist,"[[",2)
   names(weightouts)<-names(modelfitouts)
   weightoutdf<- lapply(weightouts,function(x) { as.data.frame(x) } ) %>% bind_rows


   outlist<-list(modeloutdf=modeloutdf,weightoutdf=weightoutdf)
   return(outlist)
}

SVR_validationcommonleftout<-function(traindf,testdf,y,xcols,verb=FALSE,tune=FALSE,tunefolds,permute=FALSE,yperm=NULL,outerfoldcores,tunecores,weights=FALSE,itersamplesize,niter=100,unifeatselect,nfeatures,PCA,propvarretain,chunksavename,savechunksize,validationcores){
   
   traindf<-traindf[!(is.na(traindf[,y])),]
   testdf<-testdf[!(is.na(testdf[,y])),]
   ytrain<-y
   if (permute){
   ytrain<-yperm
   }

   ####just data for current models#######
   jdcolstrain<-c(ytrain,xcols)
   jddatatrain<-traindf[,jdcolstrain]

   jdcolstest<-c(y,xcols)
   jddatatest<-testdf[,jdcolstest]

   names(jddatatest)[names(jddatatest)==y]<-ytrain

   ###create pulls#####

   pulls<-do.call(cbind,lapply(1:niter,function(x){sample(1:nrow(jddatatrain),itersamplesize,replace=TRUE)}))
   
   nchunks<-ceiling(ncol(pulls)/savechunksize)
   if ((ncol(pulls)/savechunksize)!=round(ncol(pulls)/savechunksize)){
   print("warning! niter not divisible by chunk size")
   print("possible slowing of run time with extra chunk")
   }
 
   #####print run info#######
   print("###Run INFO######")
   print("iter sample size")
   print(itersamplesize)
   print ("with this many iterations")
   print(niter)
   if (unifeatselect){
   print("unifeatselect with n features")
   print(nfeatures)
   } else if (PCA){
   print("PCA with n prop variance retained")
   print(propvarretain)
   }
   print ("outerfold cores/sample iterations in parallel")
   print (outerfoldcores)
   if (tune){
   print("tuning requested (see function for grid search params). tuning folds")
   print(tunefolds)
   }
   
   nchunks<-ceiling(ncol(pulls)/savechunksize)
   print ("job will run in this many chunks")
   print (nchunks)
   if ((ncol(pulls)/savechunksize)!=round(ncol(pulls)/savechunksize)){
   print("warning! niter not divisible by chunk size")
   print("possible slowing of run time with extra chunk")
   }

   for (currentchunk in 1:nchunks){
    chunksavenamefile<- paste0(sprintf(chunksavename,itersamplesize,itersamplesize,currentchunk),".rdata")
   if (file.exists(chunksavenamefile)){next}  	

   print("Current Chunk")
   print(currentchunk)
   pullchunkstart<-1+((currentchunk-1)*savechunksize)
   pullchunkend<-(currentchunk*savechunksize)
   if (currentchunk==max(nchunks)){pullchunkend<-ncol(pulls)}
   print ("Chunk start/end")
   print(pullchunkstart)
   print(pullchunkend)
    
   gc()
   
   chunkpull<-as.matrix(pulls[,pullchunkstart:pullchunkend])
	
	print(str(chunkpull)) 

	print("feature selection/model tuning")

	featureselectlist<-mclapply(1:dim(chunkpull)[2],mc.cores=tunecores,function(p){
	svrtunefeatselectpca(p=(pullchunkstart+(p-1)),train=jddatatrain[pulls[,(pullchunkstart+(p-1))],],y=ytrain,unifeatselect=unifeatselect,nfeatures=nfeatures,PCA=PCA,propvarretain=propvarretain,tune=tune,tunefolds=tunefolds)})

   gc()

   print("training models")
   #######parallel across iterations (pulls matrix)##############
   outlist <- mclapply(1:dim(chunkpull)[2],mc.cores=outerfoldcores, function(p){
                          svr.trainonly(foldname=(pullchunkstart+(p-1)),train=jddatatrain[pulls[,(pullchunkstart+(p-1))],],y=ytrain,tune=tune,tunefolds=tunefolds,tunecores=tunecores,unifeatselect=unifeatselect,nfeatures=nfeatures,PCA=PCA,propvarretain=propvarretain,weights=weights,featlist=featureselectlist[[p]])})
   
   gc()
   print("testing trained models on testdf")

   testpredlist<-mclapply(1:length(outlist),mc.cores=validationcores,function(p){
                             if(PCA){
                              validationset<-predict(outlist[[p]]$pcamodel,jddatatest)
                             }else if (unifeatselect){
                              validationset<-jddatatest[,outlist[[p]]$featselectednames]   
                             }
                             testpred<-predict(outlist[[p]]$svmmodel,validationset)
                             return(testpred)
                          })
   print("building chunkoutput")
   svmlabelsmat<-NA
   testpredlistmat<-do.call(cbind,testpredlist)
   if (unifeatselect){
   svmweightsmat<-sapply(outlist,function(p) p$svmweights)
   svmlabelsmat<-do.call(cbind,sapply(outlist,function(p) dimnames(p$svmweights)))
   }else if (PCA){
   svmweightsmat<-sapply(outlist,function(p){
            ncomponents<-length(p$svmweights)
            svmweightsPCAbyedge<-p$svmweights %*% t(p$pcamodel$rotation[,1:ncomponents])
                          
   })
   row.names(svmweightsmat)<-row.names(outlist[[1]]$pcamodel$rotation)
   }
    
   chunklist<-list(chunk=currentchunk,itersamplesize=itersamplesize,y=y,unifeatselect=unifeatselect,PCA=PCA,testpreds=testpredlistmat,testyvals=jddatatest[,y],svmweights=svmweightsmat,svmlabelsmat=svmlabelsmat)
   if (!file.exists(chunksavenamefile)){save(chunklist,file=chunksavenamefile)}
   rm(list=c("outlist","testpredlist","featureselectlist"))
   gc()
}
   #chunkglobnames<-sprintf(gsub("chunk%i","chunk%s",chunksavename),itersamplesize,"*")
   #chunkglobfiles<-Sys.glob(chunkglobnames)
   #chunkslists<-lapply(1:length(chunkglobfiles),function(cgi){
   #print(cgi)
   #load(chunkglobfiles[[cgi]])
   #chunk<-chunklist
   #return(chunk)})
   
   #allpreds<-do.call(cbind,lapply(1:length(chunkslists),function(cgi){testpreds<-chunkslists[[cgi]]$testpreds}))
   #allweights<--do.call(cbind,lapply(1:length(chunkslists),function(cgi){svmweights<-chunkslists[[cgi]]$svmweights}))

   #if (unifeatselect) {
   #allchunkreturn<-list(itersamplesize=itersamplesize,y=y,unifeatselect=unifeatselect,nfeatures=nfeatures,PCA=PCA,testpreds=allpreds,svmweightlabels=svmlabelsmat,svmweights=allweights,testyvals=jddatatest[,y])
   #} else if (PCA) {
   #   allchunkreturn<-list(itersamplesize=itersamplesize,y=y,unifeatselect=unifeatselect,PCA=PCA,propvarretation=propvarretation,testpreds=allpreds,svmweights=allweights,testyvals=jddatatest[,y])
  # }
   #return(chunkslists)

          
}

#######################################svm wrappers#############

svm_wrapper<-function(foldvar,df,ys,xcols,tune,tunefolds,outerfoldcores,tunecores,weights=TRUE,foldsummary=TRUE){
wrapperout<-NULL
weightsout<-NULL

for (cur_y in ys){
print(cur_y)

loocxlist <- SVR_crossvalidation(foldvar=foldvar,df,cur_y,xcols,tune=tune,tunefolds=tunefolds,outerfoldcores=outerfoldcores,tunecores=tunecores,weights=TRUE)
loocxdf<-loocxlist[["modeloutdf"]]
loocxdf$y<-cur_y
loocxdf$error<-loocxdf$testyval-loocxdf$cvpred
wrapperout<-rbind(wrapperout,loocxdf)

svmweights<-loocxlist[["weightoutdf"]]
svmweights_m<-as.data.frame(t(sapply(svmweights,mean, na.rm = T)))
svmweights_m$y<-cur_y
weightsout<-rbind(weightsout,svmweights_m)
}
wrapperreturn<-list(wrapperout=wrapperout,weightsout=weightsout)
return(wrapperreturn)
}

svm_wrapper_permute<-function(df,ys,xcols,tune,tunefolds,outerfoldcores,tunecores,nperms=1000,foldsummary=TRUE){
permwrapperout<-NULL
for (cur_y in ys){
curydf<-df
curydf<-curydf[!is.na(df[,cur_y]),]
print(cur_y)

for (p in 1:nperms){
print(p)
curydf$yperm<-sample(curydf[,cur_y])
locxlist <- SVR_crossvalidation(foldvar=foldvar,curydf,cur_y,xcols,tune=tune,tunefolds=tunefolds,outerfoldcores=outerfoldcores,tunecores=tunecores,permute=TRUE,yperm="yperm")

locx<-locxlist[["modeloutdf"]]
locx$error<-locx$testyval-locx$cvpred
permcor<-NA
permcor<-cor(as.numeric(locx$cvpred),curydf[,cur_y])
permptemp<-as.data.frame(permcor)
permptemp$y<-cur_y
permptemp$perm<-p
permptemp$rsquared<-rsquared_function(locx$testyval,locx$error)

if (foldsummary){
permptemp$foldname<-0
rsquaredfolds<-locx %>% group_by (foldname) %>% summarise(rsquared=rsquared_function(testyval,error),permcor=cor(testyval,cvpred))
rsquaredfolds$y<-cur_y
rsquaredfolds$perm<-p
permptemp<-rbind(permptemp,rsquaredfolds)
}

permwrapperout<-rbind(permwrapperout,permptemp)
}
}
return(permwrapperout)
}

############svm sample size wrappers for MP#######################
svm_samplesizewrapper<-function(traindf,testdf,y,xcols,tune=FALSE,tunefolds,outerfoldcores,tunecores,weights=TRUE,samplesizes,niter=100,niterweighted,unifeatselect,nfeatures=1000,PCA,propvarretain=.5,savedir,savechunksize,validationcores,jobname){

if (PCA){
type<-"PCA"
param<-propvarretain
}else if(unifeatselect){
type<-"unifeatselect"
param<-nfeatures
}  
sssavedirname<-paste0(savedir,"n%s/")

#basesavename<-paste(savedir,paste(paste(paste(type,param,sep="."),y,sep="."),"n%i",sep="."),sep="/")
chunksavename<-paste(sssavedirname,paste(paste(paste(paste(type,param,sep="."),y,sep="."),jobname,sep="."),"n%s.chunk%s",sep="."),sep="/")
#if (system('hostname',intern=T)=='wallace'){samplesizes<-rev(samplesizes)}


for (ss in samplesizes){

sssavedir<-sprintf(sssavedirname,ss)
print("sssaveavedir")
print(sssavedir)
if (!(dir.exists(sssavedir))){dir.create(sssavedir)}

#savename<-paste0(sprintf(basesavename,ss),".rdata")


#if (!file.exists(savename)){
svrvalidationatss<-SVR_validationcommonleftout(traindf=traindf,testdf=testdf,y=y,xcols,tune=tune,tunefolds=tunefolds,outerfoldcores=outerfoldcores,tunecores=tunecores,weights=weights,itersamplesize=ss,niter=niter,unifeatselect=unifeatselect,nfeatures=nfeatures,PCA=PCA,propvarretain=propvarretain,chunksavename=chunksavename,savechunksize=savechunksize,validationcores=validationcores)
 #  }

#if (!file.exists(savename)){
#save(svrvalidationatss,file=savename)
# }
}
}

   


