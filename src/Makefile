NVCCFLAGS=-ccbin=icpc -g -lm -m64 -arch=sm_35 --use_fast_math --default-stream per-thread --ptxas-options=-O3
NVIDIA=-I/opt/cuda/8.0/bin/nvcc/include/ -L/opt/cuda/8.0/bin/nvcc/lib64/ -lcuda
INTELFLAGS=-Xcompiler="-qopenmp -Ofast -pthread"
#NVCCFLAGS=-lm -m64 -arch=sm_35 --use_fast_math --default-stream per-thread --ptxas-options=-O3
#INTELFLAGS=-Xcompiler -fopenmp -lpthread
MPIFLAGS=-I/opt/intel/parallel_studio_xe_2016_update2/impi/5.1.3.181/include64/ -L/opt/intel/parallel_studio_xe_2016_update2/impi/5.1.3.181/lib64/ -lmpi
#DARSHAN=-L/scratch/app/darshan/darshan_intel_2016/lib

default: cfrk split

cfrk:
        nvcc $(INTELFLAGS) $(NVCCFLAGS) $(DARSHAN) $(NVIDIA) kmer_kernel.cu -lz -c
        nvcc $(INTELFLAGS) $(NVCCFLAGS) $(DARSHAN) $(NVIDIA) kmer_main.cu -lz -c
        nvcc main.cu $(INTELFLAGS) $(NVCCFLAGS) $(DARSHAN) $(NVIDIA) -c
        nvcc $(MPIFLAGS) $(NVCCFLAGS) $(DARSHAN) $(NVIDIA) mpi.cu -c -lz
        #gcc -Wall -std=c99 -pedantic -o fastasplitn.c
        nvcc mpi.o main.o kmer_kernel.o kmer_main.o $(NVCCFLAGS) $(INTELFLAGS) $(MPIFLAGS) $(DARSHAN) $(NVIDIA) -lz -o ../bin/cfrk_mpi
        rm mpi.o main.o kmer_main.o kmer_kernel.o
split:
        gcc -Wall -std=c99 -pedantic -o ../bin/fastasplitn fastasplitn.c
#serial:
#       nvcc $(NVCCFLAGS) serial.cu -o ../bin/serial -lz
clean:
        rm -f ../bin/* ./*.o
