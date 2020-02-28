#!/usr/bin/env bash
module load R/3.5.2-mkl
source /pylon5/ib5phip/foranw/paths.src.bash
DATADIR=/pylon5/ib5phip/bct16/data
subs="25 34 46 62 84 114 154 208 282 382 517 700 947 1282 1736 2350"

NJOBS=25  ###number of jobs in parallel
#COUNTER=0

export savedir="/home/bct16/data/20200211_10000feats/"
export niter=1 ###switched to running one iteration per job
export y="pea_wiscv_tss"
export ncores=1   ###make sure this matchs SBTACH -N 
export unifeatselect=1
export nfeatures=10000
export PCA=0
export propvarretain="NA"
export tune=0
export tunefolds=0
export savechunksize=1

for samplesize in $subs; do

NITER=$(bc <<< "5000/sqrt($samplesize)")
echo $NITER
ITERSEQ=$(seq 1 1 $NITER)
echo $ITERSEQ

	for iter in $ITERSEQ; do
		
	export samplesize=$samplesize
	JOBID="abcd_${samplesize}_${iter}"
	logfile=$SCRATCH/log/log-$JOBID.txt
	export JOBID=$JOBID
	
	
	outfilename="${savedir}/n${samplesize}/unifeatselect.$nfeatures.${y}.$JOBID.n${samplesize}.chunk1.rdata"	

	# check if we already have an output file
	[ -r $outfilename ] && echo "Output file $outfilename already exists, skipping" && continue

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
	sbatch -o $logfile -e $logfile -J "$JOBID" compute_svr.sh


	#[ $COUNTER -ge $NJOBS ] && exit 1
	
	done  
done

