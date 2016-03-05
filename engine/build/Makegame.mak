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

default: note debug run

#------------------------------------------------------------------------------
# DUB packages.
#------------------------------------------------------------------------------

fetch:
	dub fetch derelict-gl3     --version=1.0.18
	dub fetch derelict-sdl2    --version=1.9.7
	dub fetch derelict-util    --version=2.0.4
	dub fetch derelict-assimp3 --version=1.0.1
	dub fetch gl3n             --version=1.3.1
	dub fetch luad

SRCPATH += ~/.dub/packages/derelict-gl3-1.0.18/source/
SRCPATH += ~/.dub/packages/derelict-sdl2-1.9.7/source/
SRCPATH += ~/.dub/packages/derelict-util-2.0.4/source/
SRCPATH += ~/.dub/packages/derelict-assimp3-1.0.1/source/
SRCPATH += ~/.dub/packages/gl3n-1.3.1/

#------------------------------------------------------------------------------
# Attempt to use GDC... Failed.
#------------------------------------------------------------------------------

DMD = rdmd
#ifneq ("$(USECOMPILER)","")
#	DMD += --compiler=$(USECOMPILER)
#endif

#DMD += -m32

#ifeq ("$(USECOMPILER)","gdc")
#    DMD += $(addprefix -l, $(LIBS))
#    DMD += $(OBJS)
#    DMD += -o $(EXE)
#else
    DMD += $(addprefix -L-l, $(LIBS))
    DMD += $(addprefix -L, $(OBJS))
    DMD += -ofbin/$(EXE)
#endif

DMD += -J.
DMD += $(addprefix -I, $(SRCPATH))

#------------------------------------------------------------------------------

note:
	@echo "Use 'make help' for available options."

help:
	@echo "Usage:"
	@echo "    make default"
	@echo "    make debug [run]"
	@echo "    make release [run]"

debug: BLOB.zip $(OBJS)
	rm -f bin/$(EXE)
	$(DMD) -debug -w -gc --build-only $(MAIN)

release: BLOB.zip $(OBJS)
	rm -f bin/$(EXE)
	$(DMD) -release -O --build-only $(MAIN)
	strip --strip-all bin/$(EXE)

profile: BLOB.zip $(OBJS)
	rm -f bin/$(EXE)
	$(DMD) -profile --build-only $(MAIN)

run:
	@echo -n "Running: "
	bin/$(EXE)

#------------------------------------------------------------------------------

BLOB.zip: FORCE
	rm -f BLOB.zip
	zip -q -r -9 -y BLOB.zip $(BLOBFILES)

#------------------------------------------------------------------------------

clean:
	rm -f BLOB.zip BLOB.zip.o
	rm -f bin/$(EXE)
	find -L -name "*~" | xargs rm -f

FORCE:

