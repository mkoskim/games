###############################################################################
#
#
#
###############################################################################

MAIN=cylinderium.d

#------------------------------------------------------------------------------

EXE=
ENGINE = ../../engine/

LDFLAGS=
LIBDIRS=
LIBS=
OBJS=

BLOBFILES = data/

#------------------------------------------------------------------------------
# Add items you use to BLOB.
#------------------------------------------------------------------------------

BLOBFILES += $(ENGINE)/stock/unsorted/mesh/Cube/
BLOBFILES += $(ENGINE)/stock/unsorted/cubemaps/skybox2/

#------------------------------------------------------------------------------
# Directories containing files used by the engine itself.
#------------------------------------------------------------------------------

BLOBFILES += $(ENGINE)/render/scene3d/glsl/
BLOBFILES += $(ENGINE)/render/postprocess/glsl/
BLOBFILES += $(ENGINE)/stock/system

include $(ENGINE)/build/Makegame.mak

