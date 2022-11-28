#!/bin/bash


#SBATCH --nodes=1
#SBATCH --time=00:20:00
#SBATCH --partition=shas-testing
#SBATCH --ntasks=4
#SBATCH --job-name=gold-nano-sphere-job
#SBATCH --output=gold-nano-sphere.%j.out

module purge
module load gcc openmpi

export OMP_NUM_THREADS=4

install="/projects/$USER/install"
repo="/projects/$USER/nano_particle_glass_substrate"
src="$repo/src"
scripts="$repo/scripts"

mpirun -np 4 "${install}/bin/meep" "${src}/materials.scm" "${scripts}/gold-nano-sphere.ctl"
