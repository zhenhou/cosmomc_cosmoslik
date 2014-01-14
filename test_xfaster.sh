#!/bin/sh
#PBS -q usplanck
#PBS -l nodes=4:ppn=1
#PBS -l pvmem=20GB
#PBS -l walltime=8:00:00
#PBS -N test
#PBS -e $PBS_JOBID.err
#PBS -o $PBS_JOBID.out
#PBS -m bea

cd $PBS_O_WORKDIR
export OMP_NUM_THREADS=8
mpirun -np 4 -bynode ./cosmomc scripts/xfaster.ini
