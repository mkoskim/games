###############################################################################
#
# Building projects
#
###############################################################################

import os
Import("*")

env.SConscript("setup.py", "env")

###############################################################################
#
# Creating ZIP archives
#
###############################################################################

#------------------------------------------------------------------------------
# Find files in directory trees
#------------------------------------------------------------------------------

def findfiles(*dirs):
    result = []
    for root in dirs:
        for dir, subdirs, files in os.walk(env.subst(root)):
            for file in files:
                result.append(dir + "/" + file)
    return result

#------------------------------------------------------------------------------
# Zipping source (files) to archive (target)
#------------------------------------------------------------------------------

def zipdir(target, source, env):
    import zipfile

    target = target[0]

    zipf = zipfile.ZipFile(target.abspath, 'w', zipfile.ZIP_DEFLATED)

    rootdir = env.Dir(env["ARCHIVEROOT"]).abspath

    for file in source:
        archivename = os.path.relpath(file.abspath, rootdir)
        print(target.name, "<=", archivename)
        zipf.write(file.abspath, arcname = archivename)

    zipf.close()

env["BUILDERS"]["BLOB"] = Builder(action = zipdir, suffix = '.zip')

###############################################################################
#
# Setting environment
#
###############################################################################

#------------------------------------------------------------------------------
# Derived variables
#------------------------------------------------------------------------------

env.Append(ROOTDIR = env.Dir("#").abspath)
env.Append(OUTDIR = "$ROOTDIR/bin/")
env.Append(EXE = os.path.splitext(env.subst("$OUTDIR/$MAIN"))[0])
env.Append(DEP = os.path.splitext(env.subst("$EXE"))[0] + ".dep")

#print("EXE:", env["EXE"])
#print("DEP:", env["DEP"])

#------------------------------------------------------------------------------

env.Append(DFLAGS = [
        "-J$OUTDIR/",
        "-I$ENGINE/../",
        "-I$ENGINE/libs/DerelictASSIMP3/source/",
        "-I$ENGINE/libs/DerelictGL3/source/",
        "-I$ENGINE/libs/DerelictLua/source/",
        "-I$ENGINE/libs/DerelictSDL2/source/",
        "-I$ENGINE/libs/DerelictUtil/source/",
        "-I$ENGINE/libs/gl3n",
    ]
)

#------------------------------------------------------------------------------

env.Append(BLOBFILES = [])
env.Append(BLOBFILES = "$ENGINE/render/scene3d/glsl/")
env.Append(BLOBFILES = "$ENGINE/render/postprocess/glsl/")
env.Append(BLOBFILES = "$ENGINE/stock/system/")

env.BLOB(
    "$OUTDIR/BLOB.zip",
    findfiles(*env["BLOBFILES"]),
    ARCHIVEROOT = "$ENGINE/../"
)

#------------------------------------------------------------------------------
# Create dependencies for scons
#------------------------------------------------------------------------------

def system(cmd):
    print(cmd)
    os.system(cmd)

#------------------------------------------------------------------------------

try:
    os.mkdir(env.subst("$OUTDIR"))
except OSError:
    pass

system(env.subst("rdmd -debug --makedepend $DFLAGS -of$EXE $ROOTDIR/$MAIN > $DEP"))
env.ParseDepends("$DEP")

#------------------------------------------------------------------------------

env.Command(
    "$EXE", 
    ["$ROOTDIR/$MAIN", "$OUTDIR/BLOB.zip"],
    "rdmd -debug --build-only $DFLAGS -of$TARGET $ROOTDIR/$MAIN"
)

