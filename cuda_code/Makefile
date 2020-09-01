DEBUG_FLAGS=-g -G
RELEASE_FLAGS=--default-stream per-thread

LIST=bin/main.o bin/tests.o bin/sw.o bin/swSingleBlock.o bin/swGotoh.o bin/helpers.o

release: FLAGS = $(RELEASE_FLAGS)
release: executable

debug: FLAGS = $(DEBUG_FLAGS)
debug: bindir executable

executable: bindir $(LIST)
	nvcc ${FLAGS} $(LIST) -o bin/main

bin/%.o: %.cu bindir
	nvcc ${FLAGS} -dc $< -o $@

bindir:
	mkdir -p bin

profile: release
	sudo nvprof --unified-memory-profiling off bin/main

vprofile: release
	sudo nvprof --unified-memory-profiling off --analysis-metrics -o ${OUT} bin/main

clean:
	rm -f bin/*
