#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tipos.h"
#include "kmer.cuh"
#include "mpi.h"

int main (int argc, char *argv[])
{
   int rank, nprocs; // posição do processo e total de processo no comunicador
   char *str_rank, *arq_inic, *arq_saida;
   int k;
   lint chunkSize = 4096;

   if (argc < 4)
   {
      printf("Usage: ./kmer [dataset.fasta] [k] [outputfile] <chunkSize: Default 4096>");
      return 1;
   }
   if (argc == 5)
      chunkSize = atoi(argv[4]);
   
   MPI_Init(&argc, &argv);
   MPI_Comm_rank(MPI_COMM_WORLD, &rank);
   MPI_Comm_size(MPI_COMM_WORLD, &nprocs);
 
   arq_inic = (char*)malloc(256*sizeof(char));
   arq_saida = (char*)malloc(256*sizeof(char));

   strcpy (arq_inic, argv[1]);
   strcpy (arq_saida, argv[2]);   
   k = atoi (argv[3]);
 
   str_rank = (char*)malloc(sizeof(char));
   
   sprintf (str_rank, "%d", rank);
   strcat (arq_inic, "_");
   strcat (arq_inic, str_rank);
   strcat (arq_inic, ".fasta");

   strcat(arq_saida, "_");
   strcat(arq_saida, str_rank);
   strcat(arq_saida, ".out");
   
   cfrk(arq_inic, arq_saida, k, chunkSize);

   MPI_Finalize();
}
