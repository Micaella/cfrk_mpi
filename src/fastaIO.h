#ifndef _fastaIO_h
#define _fastaIO_h
#pragma once

#include <stdio.h>
#include <string.h>
#include <zlib.h>
#include <time.h>
#include <cuda.h>
#include "tipos.h"
#include<bits/stdc++.h>

/*int GetNs(char *FileName)
{
   char temp[64], cmd[512];
   FILE *in;
   strcpy(cmd, "grep -c \">\" ");
   strcat(cmd, FileName);
   in = popen(cmd, "r");
   fgets(temp, 64, in);
   fclose(in);
   return atoi(temp);
}*/

struct seq *ReadFasta(char *buffer, lint *nS, int rank, lint nSeq)
{
   char *line = NULL, *aux;
   size_t len = 0;
   ssize_t read, oldRead;
   struct seq *seq, *init, *next;
   int count = -1, flag = 0;
   int i=0;

   init = (struct seq*)malloc(sizeof(struct seq));
   init->next = NULL;
   
   line = strtok(buffer, "\n");
   while (line != NULL)
   {
       read = strlen(line);
       if (line[0] == '>')
       {
          next = init;
          seq = (struct seq*)malloc(sizeof(struct seq));
          seq->header = (char*)malloc(sizeof(char)*read);
          strcpy(seq->header, line);
          flag = 0;
       }
       else
       {
          if (flag == 0)
          {
             seq->seq = (char*)malloc(sizeof(char)*read);
             strcat(seq->seq, line);
             flag = 1;
          }
          else
          {
             oldRead = strlen(seq->seq);
             aux = (char*)malloc(sizeof(char)*oldRead);
             strcpy(aux, seq->seq);
             seq->seq = NULL;
             seq->seq = (char*)malloc(sizeof(char)*(read+oldRead));
             strcat(seq->seq, aux);
             strcat(seq->seq, line);
             aux = NULL;

             seq->next = NULL;
             next->next = seq;
  }
       }
       line = strtok(NULL,"\n");
   }
   return seq;
}

void ProcessTmpData(struct seq *seq, struct read *rd, lint nN, lint nS, ushort flag, int rank)
{
   lint i, j, pos = 0, seqCount = 0;
   struct seq *aux;
   aux = seq->next;

   cudaMallocHost((void**)&rd->data, sizeof(char)*(nN + nS));
   cudaMallocHost((void**)&rd->length, sizeof(int)*nS);
   cudaMallocHost((void**)&rd->start, sizeof(lint)*nS);
      
   rd->start[0] = 0;
   printf("%s\n", aux->len);
   while (aux != NULL)
   {
      for(i = 0; i < aux->len; i++)
      {
         rd->data[pos] = aux->data[i];
         pos++;
      }
      rd->data[pos] = -1;
      pos++;
      rd->length[seqCount] = aux->len;
      seqCount++;
      rd->start[seqCount] = pos;
      aux = aux->next;
   }
}

//-------------------------------------------------------------------------
struct seq *ReadFASTASequences(char *file, lint *nN, lint *nS, struct read *rd, ushort flag, int rank, lint nSeq)
{
   printf(" rank: %d entrei \n\n", rank);
   struct seq *seq, *prc;
   int len;
   lint lnN = 0;
   int i, j;
  
   seq = ReadFasta(file, nS, rank, nSeq);
   
   //for (i = 0; i < *nS; i++)
   prc = seq->next;
   while(prc != NULL)
   {
      len = strlen(seq->seq);
      seq->len = len;
      lnN += len;
      seq->data = (char*)malloc(sizeof(char) * len);
      
      for (j = 0; j < len; j++)
      {
         switch(seq->seq[j])
         {
            case 'a':
            case 'A':
               seq->data[j] = 0; break;
            case 'c':
            case 'C':
               seq->data[j] = 1; break;
            case 'g':
            case 'G':
               seq->data[j] = 2; break;
            case 't':
            case 'T':
               seq->data[j] = 3; break;
            default:
               seq->data[j] = -1; break;
         }
      }
      prc = prc->next;
    }
    
    ProcessTmpData(seq, rd, lnN, *nS, flag, rank);
    *nN = lnN + *nS;
    
    return seq;
}

#endif
