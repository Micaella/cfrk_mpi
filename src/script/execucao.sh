#!/bin/bash

k=2

for i in $(seq 2 2 2)
do
   #outdir=/home/micaella/kmer_cuda/result/AD_454SG_TIT.u.fasta_6800000_np$i
   mkdir /home/micaella/projeto/cfrk_mpi/result/SRR1513465.fasta_np$i #$outdir criando pasta para salvar o resultado

   python split.py /home/micaella/SRR1513465.fasta /home/micaella/projeto/cfrk_mpi/result/SRR1513465.fasta_np$i/ $i #fazendo o split

   mpirun -np $i /home/micaella/projeto/cfrk_mpi/bin/cfrk_mpi /home/micaella/projeto/cfrk_mpi/result/SRR1513465.fasta_np$i/SRR1513465.fasta /home/micaella/projeto/cfrk_mpi/result/SRR1513465.fasta_np$i ${k} 2048 #executando

done 
