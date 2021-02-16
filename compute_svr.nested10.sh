#!/usr/bin/env bash

#SBATCH -N 1 
#SBATCH -p RM-shared
#SBATCH --ntasks-per-node 6 
#SBATCH -t 07:00:00
#
# expects BATCH variable to exist 
#

#source $SCRATCH/../foranw/paths.src.bash
export R_LIBS=/home/bct16/Rpackages/3.5
module load R/3.5.2-mkl

export savedir=$savedir
export samplesize=$samplesize
export niter=$niter
export y=$y
export ncores=$ncores   ###make sure this matchs SBTACH -N 
export unifeatselect=$unifeatselect
export nfeatures=$nfeatures
export PCA=$PCA
export propvarretain=$propvarretain
export tune=$tune
export tunefolds=$tunefolds
export savechunksize=$savechunksize
export jobname=$JOBID
export perm=$perm

#Rscript SVRbysamplesize.R
#Rscript SVRbysamplesize.vertex.R
#Rscript SVRbysamplesize.allmeasures.R
#Rscript SVRbysamplesize.vertex.allmeasures.R

Rscript SVRbysamplesize.vertex.sensfullsample.R
#Rscript SVRbysamplesize.sensfullsample.R
