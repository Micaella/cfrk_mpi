/*
CFRK-MT - Contabilizador da Frequencia de Repetica de kmer (Multi GPU version)
Developer: Fabricio Gomes Vilasboas
Istitution: National Laboratory for Scientific Computing
*/


#include <stdio.h>
#include <pthread.h>
#include <math.h>
#include <stdint.h>
#include <omp.h>
#include <string.h>
#include "kmer.cuh"
#include "tipos.h"
#include "fastaIO.h"

//*** Global Variables ***
struct read *chunk;
lint *nS, *nN;
int offset;
int device;
int k;
char file_out[512];
FILE *outputfile;
int nt=12;
//************************

/*void DeviceInfo(FILE *outputfile, uint8_t device)
{
   cudaDeviceProp prop;

   cudaGetDeviceProperties(&prop, device);

   fprintf(outputfile, "\n\n***** Device information *****\n\n");

   fprintf(outputfile, "\tId: %d\n", device);
   fprintf(outputfile, "\tName: %s\n", prop.name);
   fprintf(outputfile, "\tTotal global memory: %ld\n", prop.totalGlobalMem);
   fprintf(outputfile, "\tMax grid size: %d, %d, %d\n", prop.maxGridSize[0], prop.maxGridSize[1], prop.maxGridSize[2]);
   fprintf(outputfile, "\tMax thread dim: %d, %d, %d\n", prop.maxThreadsDim[0], prop.maxThreadsDim[1], prop.maxThreadsDim[2]);
   fprintf(outputfile, "\tWarp size: %d\n", prop.warpSize);
   fprintf(outputfile, "\tMax threads per multiprocessor: %d\n", prop.maxThreadsPerMultiProcessor);

   fprintf(outputfile, "\n************************************\n\n");
}*/

void DeviceInfo(uint8_t device)
{
   cudaDeviceProp prop;

   cudaGetDeviceProperties(&prop, device);

   printf("\n\n***** Device information *****\n\n");

   printf("\tId: %d\n", device);
   printf("\tName: %s\n", prop.name);
   printf("\tTotal global memory: %ld\n", prop.totalGlobalMem);
   printf("\tMax grid size: %d, %d, %d\n", prop.maxGridSize[0], prop.maxGridSize[1], prop.maxGridSize[2]);
   printf("\tMax thread dim: %d, %d, %d\n", prop.maxThreadsDim[0], prop.maxThreadsDim[1], prop.maxThreadsDim[2]);
   printf("\tWarp size: %d\n", prop.warpSize);
   printf("\tMax threads per multiprocessor: %d\n", prop.maxThreadsPerMultiProcessor);

   printf("\n************************************\n\n");
}

int SelectDevice(int devCount)
{

   int i, device = 0;
   cudaDeviceProp prop[devCount];

   if (devCount > 0)
   {
      for (i = 0; i < devCount; i++)
      {
         cudaGetDeviceProperties(&prop[i], i);
      }

      for (i = 0; i < devCount; i++)
      {
         if (prop[i].totalGlobalMem > prop[device].totalGlobalMem)
         {
            device = i;
         }
      }
   }
   else
      return 0;

return device;
}

struct read* SelectChunkRemain(struct read *rd, ushort chunkSize, ushort it, lint max, lint gnS, lint *nS, lint gnN, lint *nN)
{
   struct read *chunk;
   lint i;
   lint j;
   lint length = 0;

   // Size to be allocated
   for (i = 0; i < max; i++)
   {
      lint id = chunkSize*it + i;
      if (id > gnS-1)
      {
         break;
      }
      length += rd->length[id]+1;
   }

   cudaMallocHost((void**)&chunk, sizeof(struct read));
   cudaMallocHost((void**)&chunk->data, sizeof(char)*length);
   cudaMallocHost((void**)&chunk->length, sizeof(int)*chunkSize);
   cudaMallocHost((void**)&chunk->start, sizeof(lint)*chunkSize);

   // Copy rd->data to chunk->data
   lint start = rd->start[chunkSize*it];
   lint end = start + (lint)length;

   #pragma omp parallel for num_threads(nt)
   for (j = start; j < end; j++)
   {
      chunk->data[j-start] = rd->data[j];
   }

   chunk->length[0] = rd->length[chunkSize*it];
   chunk->start[0] = 0;

   // Copy start and length
   for (i = 1; i < max; i++)
   {
      lint id = chunkSize*it + i;
      chunk->length[i] = rd->length[id];
      chunk->start[i] = chunk->start[i-1]+(chunk->length[i-1]+1);
   }

   *nN = length;
   *nS = max;
return chunk;
}


void SelectChunk(struct read *chunk, const int nChunk, struct read *rd, ushort chunkSize, lint max, lint gnS, lint *nS, lint gnN, lint *nN)
{
   lint i, j, it;

   for (it = 0; it < nChunk; it++)
   {
      lint length = 0;

      // Size to be allocated
      for (i = 0; i < max; i++)
      {
         lint id = chunkSize*it + i;
         if (id > gnS-1)
         {
            break;
         }
         length += rd->length[id]+1;
      }

      cudaMallocHost((void**)&chunk[it].data, sizeof(char)*length);
      cudaMallocHost((void**)&chunk[it].length, sizeof(int)*chunkSize);
      cudaMallocHost((void**)&chunk[it].start, sizeof(lint)*chunkSize);

      // Copy rd->data to chunk->data
      lint start = rd->start[chunkSize*it];
      lint end = start + (lint)length;

      #pragma omp parallel for num_threads(nt)
      for (j = start; j < end; j++)
      {
         chunk[it].data[j-start] = rd->data[j];
      }

      chunk[it].length[0] = rd->length[chunkSize*it];
      chunk[it].start[0] = 0;

      // Copy start and length
      for (i = 1; i < max; i++)
      {
         lint id = chunkSize*it + i;
         chunk[it].length[i] = rd->length[id];
         chunk[it].start[i] = chunk[it].start[i-1]+(chunk[it].length[i-1]+1);
      }

      nN[it] = length;
      nS[it] = max;
   }
}

void *LaunchKmer(void* threadId)
{

   lint tid = (lint)threadId;
   int start = tid * offset;
   int end = start+offset;

   printf("\t\ttid: %d\n", tid);

   DeviceInfo(tid);

   int i = 0;
   for (i = start; i < end; i++)
   {
      kmer_main(&chunk[i], outputfile, nN[i], nS[i], k, device);
      cudaStreamSynchronize(0);
      cudaFreeHost(chunk[i].data);
      cudaFreeHost(chunk[i].length);
      cudaFreeHost(chunk[i].start);
   }

return NULL;
}

int cfrk(char *dataset, char *dataout, int k, lint chunkSize, int rank, int tambuf)
{

   lint gnN, gnS;
   int devCount;

   outputfile = fopen(dataout, "a");

  /* printf(" %c \n\n", dataset[0]);
           printf(" %c \n\n", dataset[1]);*/

   /*if ( argc < 4)
   {
      printf("Usage: ./kmer [dataset.fasta] [file_out.cfrk] [k] <chunkSize: Default 8192>");
      return 1;
   } */

   cudaDeviceReset();

   /*k = atoi(argv[3]);
   if (argc == 5)
      chunkSize = atoi(argv[3]);*/

   cudaGetDeviceCount(&devCount);
   //DeviceInfo(device);

   //strcpy(file_out, argv[2]);

   fprintf(outputfile, "\ndataset: %s, out: %s, k: %d, chunkSize: %d\n", dataset, dataout, k, chunkSize);

   lint st = time(NULL);
   puts("\n\n\t\tReading seqs!!!");
   struct read *rd;
   cudaMallocHost((void**)&rd, sizeof(struct read));
   ReadFASTASequences(dataset, &gnN, &gnS, rd, 1, tambuf, rank);
   fprintf(outputfile, "\nnS: %ld, nN: %ld\n", gnS, gnN);
   lint et = time(NULL);

   fprintf(outputfile, "\n\t\tReading time: %ld\n", (et-st));

   int nChunk = floor(gnS/chunkSize);
   int i = 0;
   cudaMallocHost((void**)&chunk, sizeof(struct read)*nChunk);
   cudaMallocHost((void**)&nS, sizeof(lint)*nChunk);
   cudaMallocHost((void**)&nN, sizeof(lint)*nChunk);
   SelectChunk(chunk, nChunk, rd, chunkSize, chunkSize, gnS, nS, gnN, nN);

   device = SelectDevice(devCount);
   offset = floor(nChunk/devCount);
   pthread_t threads[devCount];
   for (i = 0; i < devCount; i++)
   {
      pthread_create(&threads[i], NULL, LaunchKmer, (void*)i);
   }

   for (i = 0; i < devCount; i++)
   {
      pthread_join(threads[i], NULL);
   }

   int threadRemain = nChunk - (offset*devCount);
   if (threadRemain > 0)
   {
      kmer_main(&chunk[nChunk-1], outputfile, nN[nChunk-1], nS[nChunk-1], k, device);
   }

   int chunkRemain = abs(gnS - (nChunk*chunkSize));
   lint rnS, rnN;
   chunk = SelectChunkRemain(rd, chunkSize, nChunk, chunkRemain, gnS, &rnS, gnN, &rnN);
   kmer_main(chunk, outputfile, rnN, rnS, k, device);

   fclose(outputfile);

return 0;
}
