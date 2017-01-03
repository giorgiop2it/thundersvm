CCFLAGS	  := -Wall
NVCCFLAGS := -arch=sm_35 -lrt -Wno-deprecated-gpu-targets -rdc=true
LASTFLAG  := -Wno-deprecated-gpu-targets 
LDFLAGS   := -I/usr/local/cuda/include -I/usr/local/cuda/samples/common/inc -lcuda -lcudadevrt -lcudart -lcublas -lpthread -lcusparse
NVCC	  := /usr/local/cuda/bin/nvcc
DISABLEW  := -Xnvlink -w

CXX := g++

ODIR = bin
exe_name = mascot
release_bin := $(ODIR)/release/$(exe_name)
debug_bin := $(ODIR)/debug/$(exe_name)
$(shell mkdir -p $(ODIR)/release)
$(shell mkdir -p $(ODIR)/debug)

FILES = $(wildcard svm-shared/*/*/*.c*) $(wildcard svm-shared/*/*.c*) $(wildcard svm-shared/*.c*) $(wildcard mascot/*.c*) $(wildcard mascot/*/*.c*) 
SOURCE = $(notdir $(FILES))						 #remove directory
OBJS := $(patsubst %.cpp, %.o,$(SOURCE:.cpp=.o)) #replace .cpp to .o
OBJ = $(patsubst %.cu, %.o,$(OBJS:.cu=.o))		 #replace .cu to .o

$(release_bin): $(OBJ)
	$(NVCC) $(LASTFLAG) $(LDFLAGS) $(DISABLEW) -o $@ $^
$(debug_bin): $(OBJ)
	$(NVCC) $(LASTFLAG) $(LDFLAGS) $(DISABLEW) -o $@ $^

.PHONY: release
.PHONY: debug

release: CCFLAGS += -O2
release: NVCCFLAGS += -O2
release: LASTFLAG += -O2
release: $(release_bin)

debug: CCFLAGS += -g
debug: NVCCFLAGS += -G -g
debug: LASTFLAG += -G -g
debug: $(debug_bin)

#compile files of svm-shared 
%.o: svm-shared/%.c* svm-shared/*.h
	$(NVCC) $(NVCCFLAGS) $(LDFLAGS) -o $@ -dc $<
	
#compile caching strategies
%.o: svm-shared/Cache/%.c* svm-shared/Cache/*.h
	$(NVCC) $(NVCCFLAGS) $(LDFLAGS) -o $@ -dc $<

#compile data reader
%.o: mascot/DataIOOps/%.cpp mascot/DataIOOps/*.h
	$(CXX) $(CCFLAGS) -o $@ -c $<
%.o: svm-shared/DataReader/%.cpp svm-shared/DataReader/*.h
	$(CXX) $(CCFLAGS) -o $@ -c $<

#compile hessian operators
%.o: svm-shared/HessianIO/%.c* svm-shared/HessianIO/*.h svm-shared/host_constant.h	
	$(NVCC) $(NVCCFLAGS) $(LDFLAGS) -o $@ -dc $<

#compile kernel value calculaters
%.o: svm-shared/kernelCalculater/%.cu svm-shared/kernelCalculater/kernelCalculater.h
	$(NVCC) $(NVCCFLAGS) $(LDFLAGS) -o $@ -dc $<
%.o: svm-shared/HessianIO/hostKernelCalculater/%.cpp svm-shared/HessianIO/hostKernelCalculater/*.h
	$(CXX) $(CCFLAGS) -o $@ -c $<

#compile files of mascot
%.o: mascot/%.c* mascot/*.h svm-shared/*.h svm-shared/HessianIO/*.h
	$(NVCC) $(NVCCFLAGS) $(LDFLAGS) -o $@ -dc $<

.PHONY:clean

clean:
	rm -f *.o  bin/*.bin bin/result.txt bin/release/* bin/debug/*
