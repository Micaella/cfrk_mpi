#!/usr/bin/python

import sys
import math

def correct(input, output):

   inputfile = open(input)
   outputfile = open(output, 'w')

   content = inputfile.readlines()

   inputfile.close()

   i = 0
   while content != "":
      try:
         seq = content[i+1]
         header = '>' + content[i].split(' ')[0][1:] + ' len(' + str(len(seq)-1) + ')' + '<-----\n'
         new_seq = ''
         j = 0;
         while j < len(seq):
            new_seq += seq[j]
            if (j+1) % 70 == 0 and j != 0 and (j+2) < len(seq):
               new_seq+='\n'
            j+=1
         outputfile.write(header)
         outputfile.write(new_seq)
         i+=4
      except:
         break

def read_FASTA_strings(filename):
      with open(filename) as file:
         return file.read().split('>')[1:]

def read_FASTA_entries(filename):
      return [seq.partition('\n') for seq in read_FASTA_strings(filename)]

def read_FASTA_sequences(filename):
   return [[seq[0][1:],
             seq[2].replace('\n', '')]
          for seq in read_FASTA_entries(filename)]

if __name__ == "__main__":
   filein = sys.argv[1]
   outdir = sys.argv[2]
   np = int(sys.argv[3])

   arq = open(filein, "r")

   nS = 0
   for linha in arq.readlines():
      if linha[0] == ">":
         nS = nS + 1

   bloco = math.ceil(nS/np)
   resto = nS-(bloco*np)

   fileout = list()
   for i in range(0, np):
      tmp = "tmp" + filein + "_" + str(i)
      fileout.append(tmp)

   seq = read_FASTA_sequences(filein)

   arq.close()

   for i in range(1, np+1):
      tmp = outdir + filein.split("/")[-1] + "_" + str((i-1)) + "tmp"
      arq = open(tmp, "w")
      auxbloco = bloco
      if i < np:
         auxbloco = bloco + 1
      start = (i-1) * int(auxbloco)
      end   = i * int(auxbloco)
      for j in range(start, end):
        arq.write(seq[j][0])
        arq.write("\n")
        arq.write(seq[j][1])
        arq.write("\n")
      out = outdir + filein.split("/")[-1] + "_" + str((i-1))
      correct(tmp, out)

