#!/bin/python

import sys

if __name__ == "__main__":

   if len(sys.argv) < 3:
      print '[ERRO] Erro de sintaxe. Tente: python fastaq2fasta.py <input file> <output file>'
      exit(1)

   input = sys.argv[1]
   output = sys.argv[2]

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
