#!/bin/bash
#SBATCH --nodes=3                      #Numero de Nós
#SBATCH --ntasks-per-node=1            #Numero de tarefas por Nó
#SBATCH --ntasks=3                     #Numero total de tarefas MPI
#SBATCH --cpus-per-task=24             #Numero de threads por tarefa MPI
#SBATCH -p nvidia_small                  #Fila (partition) a ser utilizada
#SBATCH -J mcfrk                       #Nome job
#SBATCH --time=01:00:00
#SBATCH --exclusive                    #Utilização exclusiva dos nós durante a execução do job

#source /scratch/app/modulos/intel-psxe-2017.1.043.sh
source /scratch/app/modulos/intel-psxe-2016.2.062.sh
module load cuda/8.0
module load openmpi/2.1_intel

export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi.so
export I_MPI_EXTRA_FILESYSTEM=on
export I_MPI_EXTRA_FILESYSTEM_LIST=lustre

ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited

   proc=3
   k=2

#/usr/bin/time -f "%e" srun --resv-ports -n ${proc} /scratch/cenapadrjsd/micaella.paula/mcfrk_v4/bin/cfrk_mpi /scratch/cenapadrjsd/micaella.paula/mcfrk_v4/frag002.fasta /scratch/cenapadrjsd/micaella.paula/mcfrk_v4/result/frag002 ${k} 202

/usr/bin/time -f "%e" srun --resv-ports -n ${proc} /scratch/cenapadrjsd/micaella.paula/mcfrk_v4/bin/cfrk_mpi /scratch/cenapadrjsd/micaella.paula/mcfrk_v4/SRR4030096_0.fasta /scratch/cenapadrjsd/micaella.paula/mcfrk_v4/result/SRR4030096 ${k} 202
