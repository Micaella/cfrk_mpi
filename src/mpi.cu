#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "tipos.h"
#include "kmer.cuh"
#include "mpi.h"

void lersequencia (char *buf, int bufsizeInt, int rank, int *aux)
{

   int i = bufsizeInt;
   int j = 0;

   while ( i > 0)
   {
      if (buf[i] == '>')
      {
         *aux = i;
         j = j + 1;
         break;
      }
      else //serve para qnd o processo não tem inicio de sequencia
      {
         *aux = bufsizeInt;
         i = i - 1;
      }
   }
}

int main (int argc, char *argv[])
{
   int rank, nprocs; // posição do processo e total de processo no comunicador
   char *str_rank, *arq_inic, *arq_saida, hostname[MPI_MAX_PROCESSOR_NAME];
   int k, bufsize_new=0, bufsizeInt=0, i=0, dest=0;
   double bufsizeDouble=0;
   lint chunkSize = 4096;
   char *buf;
   int aux=0, tag1=1;
   /*para o novo deslocamento de cada view
   vet_send e vet_recv: primeira posição ultima visualizão do processo, segunda posição quantidade de dados que o processo terá que acresentar em sua nova visualização*/
   int inic_view_atual=0;
   int vet_send[2]= {0,0}, vet_recv[2]={0,0};

   if (argc < 4)
   {
      printf("Usage: ./kmer [dataset.fasta] [k] [outputfile] <chunkSize: Default 4096>");
      return 1;
   }
   if (argc == 5)
      chunkSize = atoi(argv[4]);

   MPI_Init(&argc, &argv);
   MPI_File fh;
   MPI_Status status;
   MPI_Offset filesize;
   MPI_Datatype filetype;
   MPI_Request r;
   MPI_Comm_rank(MPI_COMM_WORLD, &rank);
   MPI_Comm_size(MPI_COMM_WORLD, &nprocs);

   arq_inic = (char*)malloc(256*sizeof(char));
   arq_saida = (char*)malloc(256*sizeof(char));
   strcpy (arq_inic, argv[1]);
   strcpy (arq_saida, argv[2]);
   k = atoi (argv[3]);
   str_rank = (char*)malloc(sizeof(char));

   MPI_File_open(MPI_COMM_WORLD, arq_inic, MPI_MODE_RDONLY, MPI_INFO_NULL, &fh);

   MPI_File_get_size(fh, &filesize);

   bufsizeDouble = ((double)filesize / nprocs);
   bufsizeInt = ceil(bufsizeDouble);
   buf = (char *)malloc(bufsizeInt * sizeof(char));

   //printf("bufsize: %d \n", bufsizeInt);
   //printf("filesize: %d \n", filesize);

   MPI_Barrier(MPI_COMM_WORLD);

   MPI_File_set_view(fh, rank*bufsizeInt, MPI_CHAR, filetype, "native", MPI_INFO_NULL);

   MPI_File_read_at_all(fh, rank*bufsizeInt, buf, bufsizeInt, MPI_CHAR, &status);

   lersequencia(buf, bufsizeInt, rank, &aux);

   //comunicação para saber quantos dados a mais irei ler (vcopy) e quantidade que o processo anterior temninava sua visualização (end_view_prsant)
   vet_send[0]= (rank*bufsizeInt)+bufsizeInt-1;
   vet_send[1]= bufsizeInt - aux;
   //printf("vet_send [0]: %d, vet_send [1]: %d rank:%d\n\n", vet_send[0], vet_send[1], rank);

   MPI_Irecv(vet_recv, 2, MPI_INT, MPI_ANY_SOURCE, tag1, MPI_COMM_WORLD, &r);
   if(rank != nprocs-1)
   {
      dest = rank + 1;
      MPI_Isend(vet_send, 2, MPI_INT, dest, tag1, MPI_COMM_WORLD, &r);
   }

   MPI_Barrier(MPI_COMM_WORLD);

   //printf("vet_recv [0]: %d, vet_recv [1]: %d rank:%d\n\n", vet_recv[0], vet_recv[1], rank);

   //Inicio da nova view
   inic_view_atual = vet_recv[0] - vet_recv[1];
   //printf("inicio da minha view agora: %d, rank: %d\n", inic_view_atual, rank);

   //calculo para saber novo tamanho do buffer, a partir dos valores de recevi e enviei
   if(rank != nprocs-1)
   {
      bufsize_new = (bufsizeInt+vet_recv[1])-vet_send[1];
   }
   else
   {
      bufsize_new = (bufsizeInt+vet_recv[1])-0;
   }
   printf("tam buf agr: %d, rank: %d\n", bufsize_new, rank);

   //Início da nova visualização
   free(buf);

   buf = (char *)malloc(bufsize_new * sizeof(char));

   if(rank == 0)
   {
      MPI_File_read_at_all(fh, rank*bufsize_new, buf, bufsize_new-1, MPI_CHAR, &status);
   }
   else
   {
      MPI_File_read_at_all(fh, inic_view_atual+1, buf, bufsize_new, MPI_CHAR, &status);
   }

   /*if(rank == 0)
   {
      for(i=0; i<bufsize_new; i++)
      {
         printf("rank: %d, read: %c i: %d\n", rank, buf[i], i);
      }
   }*/

   MPI_Barrier(MPI_COMM_WORLD);

   sprintf (str_rank, "%d", rank);
   strcat(arq_saida, "_");
   strcat(arq_saida, str_rank);
   strcat(arq_saida, ".out");

   cfrk(buf, arq_saida, k, chunkSize, rank, bufsize_new);
   MPI_File_close(&fh);
   MPI_Finalize();
}
