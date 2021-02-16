#!/usr/bin/env Rscript
#
##load data##########################

batch<-as.numeric(Sys.getenv("BATCH"))
savedir<-as.character(Sys.getenv("savedir"))
samplesize<-as.numeric(Sys.getenv("samplesize"))
niter<-as.numeric(Sys.getenv("niter"))
y<-as.character(Sys.getenv("y"))
ncores<-as.numeric(Sys.getenv("ncores"))
unifeatselect<-as.logical(as.numeric(Sys.getenv("unifeatselect")))
nfeatures=as.numeric(Sys.getenv("nfeatures"))
PCA<-as.logical(as.numeric(Sys.getenv("PCA")))
propvarretain<-as.numeric(Sys.getenv("propvarretain"))
tune<-as.logical(as.numeric(Sys.getenv("tune")))
tunefolds<-as.numeric(Sys.getenv("tunefolds"))
savechunksize<-as.numeric(Sys.getenv("savechunksize"))
jobname<-as.character(Sys.getenv("jobname"))
perm<-as.logical(as.numeric(Sys.getenv("perm")))
resample=TRUE

print(ls())
print(Sys.time())

print(savedir)
print(samplesize)
print(niter)
print(y)
print(ncores)
print(unifeatselect)
print(nfeatures)
print(PCA)
print(propvarretain)
print(tune)
print(tunefolds)
print(savechunksize)


load("/home/bct16/data/traindatadf.vertex.Rdata")
load("/home/bct16/data/testdatadf.vertex.Rdata")

source("/home/bct16/scripts/ABCD_MP_SVR/0x_svrfuncs.R")
traindf<-traindfvertex
testdf<-testdfvertex
xcols<-grep("Vertex",names(traindf),value=TRUE)

traindf<-traindf[complete.cases(traindf[,xcols]),]
testdf<-testdf[complete.cases(testdf[,xcols]),]

if (perm){
traindf$yperm<-sample(traindf[,y],)
permname<-paste(y,"perm",sep="_")
names(traindf)[names(traindf)=="yperm"]<-permname
testdf[,permname]<-testdf[,y]
y<-permname
resample=FALSE
}

print("dim train test")
print(dim(traindf))
print(dim(testdf))

gc()
print(ls())


print(Sys.time())
svm_samplesizewrapper(traindf=traindf,testdf=testdf,y=y,xcols=xcols,tune=tune,tunefolds=tunefolds,outerfoldcores=ncores,tunecores=ncores,weights=TRUE,samplesizes=samplesize,niter=niter,unifeatselect=unifeatselect,nfeatures=nfeatures,PCA=PCA,propvarretain=propvarretain,savedir=savedir,savechunksize=savechunksize,validationcores=ncores,jobname=jobname,resample=resample)
print(Sys.time())



