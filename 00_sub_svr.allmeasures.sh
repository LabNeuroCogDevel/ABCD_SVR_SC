#!/usr/bin/env bash
module load R/3.5.2-mkl
#source /pylon5/ib5phip/foranw/paths.src.bash
DATADIR=/pylon5/ibz3a7p/bct16/data
#subs="25 33 45 60 80 100 145 200 256 350 460 615 825 1100 1475 1964" ##rest
#subs="25 33 45 60 80 100 145 200 256 350 460 615 825 1100 1475 1814" ## structural
#subs="300 1000 1964"
subs="1964"
NJOBS=100  ###number of jobs in parallel
#COUNTER=0
props=$(seq 0.1 0.1 1)
allys="incometoneeds abcd_pgbi01.interview_age height weight BMI abcd_ypre101.prescan_state_sleepy_1 income numpeeps abcd_tbss01.nihtbx_picvocab_agecorrected abcd_tbss01.nihtbx_flanker_agecorrected abcd_tbss01.nihtbx_list_agecorrected abcd_tbss01.nihtbx_cardsort_agecorrected abcd_tbss01.nihtbx_pattern_agecorrected abcd_tbss01.nihtbx_picture_agecorrected abcd_tbss01.nihtbx_reading_agecorrected abcd_tbss01.nihtbx_fluidcomp_agecorrected abcd_tbss01.nihtbx_cryst_agecorrected abcd_tbss01.nihtbx_totalcomp_agecorrected abcd_ps01.pea_wiscv_tss abcd_mrinback02.tfmri_nback_all_beh_correct.total_mean.rt abcd_sst02.tfmri_sst_all_beh_correct.go_mean.rt abcd_cbcls01.cbcl_scr_syn_anxdep_t abcd_cbcls01.cbcl_scr_syn_withdep_t abcd_cbcls01.cbcl_scr_syn_somatic_t abcd_cbcls01.cbcl_scr_syn_social_t abcd_cbcls01.cbcl_scr_syn_thought_t abcd_cbcls01.cbcl_scr_syn_attention_t abcd_cbcls01.cbcl_scr_syn_rulebreak_t abcd_cbcls01.cbcl_scr_syn_aggressive_t abcd_cbcls01.cbcl_scr_syn_internal_t abcd_cbcls01.cbcl_scr_syn_external_t abcd_cbcls01.cbcl_scr_syn_totprob_t abcd_mhy02.pps_y_ss_number abcd_mhy02.pps_y_ss_severity_score abcd_mhy02.bis_y_ss_bis_sum abcd_mhy02.bis_y_ss_bas_rr abcd_mhy02.bis_y_ss_bas_drive abcd_mhy02.bis_y_ss_bas_fs abcd_mhy02.upps_y_ss_lack_of_perseverance abcd_mhy02.upps_y_ss_lack_of_planning abcd_mhy02.upps_y_ss_sensation_seeking abcd_mhy02.upps_y_ss_positive_urgency abcd_mhy02.upps_y_ss_negative_urgency"

export savedir="/home/bct16/data/PCAdim_20200609allvars/"
export niter=1 ###switched to running one iteration per job
export ncores=1   ###make sure this matchs SBTACH -N 
export unifeatselect=0
export nfeatures="NA"
export PCA=1
#export propvarretain=".5"
export tune=0
export tunefolds=0
export savechunksize=1
export perm=0


#samplesize=$subs
for samplesize in $subs; do
for pv in $props; do
export propvarretain=$pv

echo $samplesize
for y in $allys; do 
echo $y 
export y=$y

#NITER=$(bc <<< "5000/sqrt($samplesize)")
NITER=1
echo $NITER
ITERSEQ=$(seq 1 1 $NITER)
#echo $ITERSEQ


	for iter in $ITERSEQ; do
	
	export samplesize=$samplesize
	JOBID="abcd_${samplesize}_${iter}_${pv}_${y}_allvars"
	logfile=$SCRATCH/log/log-$JOBID.txt
	export JOBID=$JOBID
	

	outfilename="${savedir}/PCA.${pv}.NOTUNE.$JOBID.${y}.n${samplesize}.chunk1.rdata"	


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
	
	sbatch -o $logfile -e $logfile -J "$JOBID" compute_svr.sh

	#[ $COUNTER -ge $NJOBS ] && exit 1
	
	done  
done
done
done
