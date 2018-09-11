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

SRCPATH += engine/libs/DerelictUtil/source/
SRCPATH += engine/libs/DerelictGL3/source/
SRCPATH += engine/libs/DerelictSDL2/source/
SRCPATH += engine/libs/DerelictASSIMP3/source/
SRCPATH += engine/libs/DerelictLua/source/
SRCPATH += engine/libs/gl3n/

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
DMD += -J.
DMD += -w
DMD += -O
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

#DBGINFO = -g

ifeq ("$(DBGINFO)","")
STRIP = strip --strip-all bin/$(EXE)
endif

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
	$(DMD) -debug $(DBGINFO) --build-only $(MAIN)
	$(STRIP)

release: BLOB.zip $(OBJS)
	rm -f bin/$(EXE)
	$(DMD) -release --build-only $(MAIN)
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

