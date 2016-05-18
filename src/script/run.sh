#!/bin/bash

k=4

for i in `seq 1 2 2`
do
   mkdir -p /home/fabricio/Documentos/bioinfo/projetos/kmer_cuda/seqs/frag/AD_454SG_TIT.u.fasta_6800000_mpi_${i}
   mkdir -p /home/fabricio/Documentos/bioinfo/projetos/kmer_cuda/result/AD_454SG_TIT.u.fasta_6800000_mpi_${i}

   python split.py /home/fabricio/Documentos/bioinfo/projetos/kmer_cuda/seqs/fasta/AD_454SG_TIT.u.fasta_6800000 /home/fabricio/Documentos/bioinfo/projetos/kmer_cuda/seqs/frag/AD_454SG_TIT.u.fasta_6800000_mpi_${i}/ ${i}

   /usr/bin/time -o /home/fabricio/Documentos/bioinfo/projetos/kmer_cuda/result/AD_454SG_TIT.u.fasta_6800000_mpi_${i}/time.out mpirun -np ${i} /home/fabricio/Documentos/bioinfo/projetos/kmer_cuda/bin/parallel-nucleotides-cuda-mpi /home/fabricio/Documentos/bioinfo/projetos/kmer_cuda/seqs/frag/AD_454SG_TIT.u.fasta_6800000_mpi_${i}/AD_454SG_TIT.u.fasta_6800000 /home/fabricio/Documentos/bioinfo/projetos/kmer_cuda/result/AD_454SG_TIT.u.fasta_6800000_mpi_${i} ${k}
done

