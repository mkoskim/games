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
# D libraries
#------------------------------------------------------------------------------

SRCPATH += $(ENGINE)/../
SRCPATH += $(ENGINE)/libs/DerelictUtil/source/
SRCPATH += $(ENGINE)/libs/DerelictGL3/source/
SRCPATH += $(ENGINE)/libs/DerelictSDL2/source/
SRCPATH += $(ENGINE)/libs/DerelictASSIMP3/source/
SRCPATH += $(ENGINE)/libs/DerelictLua/source/
SRCPATH += $(ENGINE)/libs/gl3n/

#------------------------------------------------------------------------------
# Submodule versions (just as reminder)
#------------------------------------------------------------------------------

subinfo:
	git submodule --quiet foreach 'echo $$name `git status | head -n 1`'

#submodules_add:
#	git submodule add https://github.com/DerelictOrg/DerelictUtil.git
#	git submodule add https://github.com/DerelictOrg/DerelictGL3.git
#	git submodule add https://github.com/DerelictOrg/DerelictSDL2.git
#	git submodule add https://github.com/DerelictOrg/DerelictASSIMP3.git
#	git submodule add https://github.com/DerelictOrg/DerelictLua.git
#	git submodule add https://github.com/Dav1dde/gl3n.git
#
#submodules_fetch:
#	git submodule update --init --recursive

#------------------------------------------------------------------------------
# Attempt to use GDC... Failed.
#------------------------------------------------------------------------------

DMD = rdmd

#------------------------------------------------------------------------------

#DMD += -m32

DMD += -ofbin/$(EXE)
DMD += -Jbin/
DMD += -w
DMD += -O
DMD += -g
DMD += $(DMDOPTS)
DMD += $(addprefix -I, $(SRCPATH))
DMD += $(addprefix -L-l, $(LIBS))
DMD += $(addprefix -L, $(OBJS))

#------------------------------------------------------------------------------
# Transition flags for delaying code changes between compiler version changes.
# To be removed when code changes are ready.
#------------------------------------------------------------------------------

#DMD_TRANSITION_FLAGS += -transition=intpromote

DMD += $(DMD_TRANSITION_FLAGS)

#------------------------------------------------------------------------------

note:
	@echo "Use 'make help' for available options."

help:
	@echo "Usage:"
	@echo "    make default"
	@echo "    make debug [run]"
	@echo "    make release [run]"

#------------------------------------------------------------------------------

debug: bin/BLOB.zip $(OBJS)
	$(DMD) -debug --build-only $(MAIN)

release: bin/BLOB.zip $(OBJS)
	$(DMD) -release --build-only $(MAIN)
	strip --strip-all bin/$(EXE)

profile: bin/BLOB.zip $(OBJS)
	$(DMD) -profile --build-only $(MAIN)

run:
	@echo -n "Running: "
	bin/$(EXE)

#------------------------------------------------------------------------------

logger:
	engine/build/logger.py -f bin/$(EXE) &

#------------------------------------------------------------------------------

bin/BLOB.zip: FORCE
	-mkdir bin
	zip -q -r -9 -y $@ $(BLOBFILES)

#------------------------------------------------------------------------------

clean:
	rm -rf bin/
	find -L -name "*~" | xargs rm -f

FORCE:

