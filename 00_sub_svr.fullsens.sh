#!/usr/bin/env bash
module load R/3.5.2-mkl
#source /pylon5/ib5phip/foranw/paths.src.bash
DATADIR=/pylon5/ibz3a7p/bct16/data
#subs="25 33 45 60 80 100 145 200 256 350 460 615 825 1100 1475 1964" ##rest
#subs="25 33 45 60 80 100 145 200 256 350 460 615 825 1100 1475 1814" ## structural
#subs="300 1000 1964"
#subs="1814"
subs="1964"
NJOBS=1  ###number of jobs in parallel
#COUNTER=0
#ys="abcd_cbcls01_cbcl_scr_syn_totprob_t abcd_tbss01_nihtbx_totalcomp_agecorrected"
ys="abcd_tbss01_nihtbx_totalcomp_agecorrected"
#props=".1 .2 .3 .4 .5 .6 .7 .8 .9 1"
#props=$(seq 0.1 0.1 1)
#props=.9
echo "props $props"
export savedir="/home/bct16/data/fullsamplesensivity_20200819/"
export niter=1 ###switched to running one iteration per job
#export y="abcd_ps01_pea_wiscv_tss"
#export y="abcd_cbcls01_cbcl_scr_syn_totprob_t"
#export y="abcd_tbss01_nihtbx_cryst_agecorrected"
#export y="abcd_tbss01_nihtbx_totalcomp_agecorrected"
export ncores=1   ###make sure this matchs SBTACH -N 
export unifeatselect=0
export nfeatures="NA"
export PCA=1
export propvarretain=".5"
export tune=0
export tunefolds=0
export savechunksize=1
export perm=0

samplesize=$subs
for samplesize in $subs; do

#for pv in $props; do
for y in $ys; do
export y=$y
pv="0.5"
pvshort=".5"
echo $pv
#NITER=$(bc <<< "5000/sqrt($samplesize)")
NITER=1000
echo $NITER
ITERSEQ=$(seq 1 1 $NITER)
#echo $ITERSEQ
export propvarretain=$pv

	for iter in $ITERSEQ; do
	
	export samplesize=$samplesize
	JOBID="abcd_${samplesize}_${iter}_${pvshort}"
	logfile=$SCRATCH/log/log-$JOBID.txt
	export JOBID=$JOBID
	

	outfilename="${savedir}/PCA.${pv}.TUNE.$JOBID.${y}.n${samplesize}.chunk1.rdata"	


	# check if we already have an output file
	[ -r $outfilename ] && echo "Output file $outfilename already exists, skipping" && continue
	echo $outfile
	# check that subject doesn't already exist
	squeue -o "%.18i %.9P %j %.8u %.8T %.10M %.9l %.6D %R" -A $(id -gn) | grep $JOBID && echo "$JOBID in queue"  && continue

	#let COUNTER=COUNTER+1

	while true; do 
		COUNTER=$(squeue -o "%.18i %.9P %j %.8u %.8T %.10M %.9l %.6D %R" -A $(id -gn) | wc -l)	
		[ $COUNTER -le $NJOBS ] && break
		echo "waiting $COUNTER"
		sleep 10 
	done
	# submit job to batch queue
	echo "$COUNTER: $samplesize $iter $outfilename "
	
	sbatch -o $logfile -e $logfile -J "$JOBID" compute_svr.fullsens.sh

	#[ $COUNTER -ge $NJOBS ] && exit 1
	
	done  
done
done
