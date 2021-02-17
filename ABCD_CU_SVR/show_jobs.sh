#!/usr/bin/env bash


jobs=$(squeue -o "%.18i %.9P %j %.8u %.8T %.10M %.9l %.6D %R" -A $(id -gn))
echo "$jobs"| grep JOBID
echo "$jobs"| grep PENDING
echo "$jobs"|grep PENDING|grep -v JOBID|wc -l
echo "$jobs"| grep -v PENDING
echo "$jobs"|grep -v PENDING|grep -v JOBID|wc -l
