NVCCFLAGS=-lm -m64 -arch=sm_20 -O3
MPIFLAGS= -I/usr/include/mpich-x86_64 -L/usr/lib64/mpich/lib -lmpich 

default: mpi

mpi:
	nvcc $(NVCCFLAGS) kmer_kernel.cu -lz -c
	nvcc $(NVCCFLAGS) kmer_main.cu -lz -c
	nvcc $(NVCCFLAGS) main.cu -c
	nvcc $(MPIFLAGS)  mpi.cu -c -lz
	nvcc $(MPIFLAGS) $(NVCCFLAGS) mpi.o kmer_kernel.o main.o kmer_main.o -lz -o ../bin/cfrk_mpi
	rm mpi.o kmer_kernel.o kmer_main.o main.o
clean:
	rm -f ../bin/* ./*.o
