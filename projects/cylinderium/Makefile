###############################################################################
#
#
#
###############################################################################

MAIN=cylinderium.d

#------------------------------------------------------------------------------

EXE=

LDFLAGS=
LIBDIRS=
LIBS=
OBJS=

BLOBFILES = data/

#------------------------------------------------------------------------------
# Add items you use to BLOB.
#------------------------------------------------------------------------------

BLOBFILES += engine/stock/unsorted/mesh/Cube/
BLOBFILES += engine/stock/unsorted/cubemaps/skybox2/

#------------------------------------------------------------------------------
# Directories containing files used by the engine itself.
#------------------------------------------------------------------------------

BLOBFILES += engine/render/scene3d/glsl/
BLOBFILES += engine/render/postprocess/glsl/
BLOBFILES += engine/stock/system

include engine/build/Makegame.mak

