#include <stdio.h>
#include <pthread.h>
#include <math.h>
#include <stdint.h>
#include "kmer.cuh"
#include "tipos.h"
#include "fastaIO.h"
#include "string.h"

void DeviceInfo(FILE *outputfile, uint8_t device)
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

struct read* SelectChunk(struct read *rd, ushort chunkSize, ushort it, lint gnS, lint *nS, lint gnN, lint *nN)
{
   struct read *chunk;
   int i;
   lint length = 0;

   // Size to be allocated
   for (i = 0; i < chunkSize; i++)
   {
      int id = chunkSize*it + i;
      if (id > gnS-1)
      {
         break;
      }
      length += rd->length[id]+1;
   }

   cudaMallocHost((void**)&chunk, sizeof(struct read));
   cudaMallocHost((void**)&chunk->data, sizeof(short)*length);
   cudaMallocHost((void**)&chunk->length, sizeof(int)*chunkSize);
   cudaMallocHost((void**)&chunk->start, sizeof(int)*chunkSize);

   // Copy rd->data to chunk->data
   lint start = rd->start[chunkSize*it];
   lint end = start + length;
   for (i = start; i < end; i++)
   {
      chunk->data[i-start] = rd->data[i];
   }

   chunk->length[0] = rd->length[chunkSize*it];
   chunk->start[0] = 0;
   // Copy start and length
   for (i = 1; i < chunkSize; i++)
   {
      int id = chunkSize*it + i;
      chunk->length[i] = rd->length[id];
      chunk->start[i] = chunk->start[i-1]+(chunk->length[i-1]+1);
   }

   *nN = length;
   *nS = chunkSize;
return chunk;
}

int cfrk(char *dataset, char *dataout, int k, lint chunkSize)
{

   int device;
   lint gnN, gnS, nS, nN;
   int devCount;

   FILE *outputfile;
   outputfile = fopen(dataout, "a");
   
   cudaDeviceReset();
   
   cudaGetDeviceCount(&devCount);
   device = SelectDevice(devCount);
   DeviceInfo(outputfile, device);

   //fprintf(outputfile, "\ndataset: %s, k: %d, chunkSize: %d\n", dataset, k, chunkSize);
   printf("\ndataset: %s, k: %d, chunkSize: %d\n", dataset, k, chunkSize);

   lint st = time(NULL);
   puts("\n\n\t\tReading seqs!!!");
   struct read *rd;
   cudaMallocHost((void**)&rd, sizeof(struct read));
   ReadFASTASequences(dataset, &gnN, &gnS, rd, 1);
   fprintf(outputfile, "\nnS: %ld, nN: %ld\n", gnS, gnN);
   lint et = time(NULL);

   fprintf(outputfile, "\n\t\tReading time: %ld\n", (et-st));

   int nChunk = floor(gnS/chunkSize);
   struct read *chunk;
   printf("passei aqui 1 \n");
   for (int i = 0; i < nChunk; i++)
   {
      chunk = SelectChunk(rd, chunkSize, i, gnS, &nS, gnN, &nN);
      kmer_main(chunk, outputfile, nN, nS, k, device);
      cudaFree(chunk->data);
      cudaFree(chunk->length);
      cudaFree(chunk->start);
      cudaFree(chunk);
   }
   printf("passei aqui 2 \n");
   int chunkRemain = abs(gnS - (nChunk*chunkSize));
   chunk = SelectChunk(rd, chunkRemain, nChunk, gnS, &nS, gnN, &nN);
   fprintf(outputfile, "\nnS: %ld, nN: %ld, chunkRemain: %d\n", nS, nN, chunkRemain);
   kmer_main(chunk, outputfile, nN, nS, k, device);

   fclose(outputfile);

return 0;
}
