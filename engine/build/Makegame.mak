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

SRCPATH += ~/.dub/packages/derelict-gl3-1.0.12/source/
SRCPATH += ~/.dub/packages/derelict-sdl2-1.9.5/source/
SRCPATH += ~/.dub/packages/derelict-util-2.0.0/source/
SRCPATH += ~/.dub/packages/derelict-assimp3-1.0.1/source/
SRCPATH += ~/.dub/packages/gl3n-1.1.0/

#------------------------------------------------------------------------------

DMD = rdmd
#DMD += --compiler=gdmd
#DMD += -m32
DMD += -ofbin/$(EXE)
DMD += $(addprefix -I, $(SRCPATH))
DMD += $(addprefix -L-l, $(LIBS))
DMD += $(addprefix -L, $(OBJS))

DMD += -J.

#------------------------------------------------------------------------------

usage:
	@echo "Usage:"
	@echo "    make default"
	@echo "    make debug run"
	@echo "    make release run"

default: debug run

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
	zip -q -r -9 BLOB.zip $(BLOBFILES)

#------------------------------------------------------------------------------

clean:
	rm -f BLOB.zip BLOB.zip.o
	rm -f bin/$(EXE)
	find -L -name "*~" | xargs rm -f

FORCE:

