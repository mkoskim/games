###############################################################################
#
#
#
###############################################################################

#------------------------------------------------------------------------------

ifeq ("$(EXE)","")
	EXE=$(basename $(MAIN))
endif

#------------------------------------------------------------------------------

SRCPATH+=~/.dub/packages/derelict-gl3-1.0.12/source/
SRCPATH+=~/.dub/packages/derelict-sdl2-1.9.5/source/
SRCPATH+=~/.dub/packages/derelict-util-1.9.1/source/
SRCPATH+=~/.dub/packages/gl3n-1.1.0/

#------------------------------------------------------------------------------

DMD=rdmd
#DMD+=--compiler=gdmd
#DMD+=-m32
DMD+=-ofbin/$(EXE)
DMD+=$(addprefix -I, $(SRCPATH))
DMD+=$(addprefix -L-l, $(LIBS))

#------------------------------------------------------------------------------

usage:
	@echo "Usage:"
	@echo "    make default"
	@echo "    make debug run"
	@echo "    make release run"

default: debug run

debug: BLOB.zip
	rm -f bin/$(EXE)
	$(DMD) -w -debug -gc --build-only -LBLOB.zip.o $(MAIN)

release: BLOB.zip
	rm -f bin/$(EXE)
	$(DMD) -O --build-only -LBLOB.zip.o $(MAIN)
	strip --strip-all bin/$(EXE)

run:
	bin/$(EXE)

#------------------------------------------------------------------------------

BLOB.zip: FORCE
	rm -f BLOB.zip
	zip -r -9 BLOB.zip $(BLOBFILES)
	gcc -c engine/build/blob.S -o BLOB.zip.o

#------------------------------------------------------------------------------

clean:
	rm -f BLOB.zip BLOB.zip.o
	rm -f bin/$(EXE)
	find -L -name "*~" | xargs rm -f

FORCE:

