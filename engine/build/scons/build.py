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
env.Append(EXE = os.path.splitext(env.subst("$OUTDIR/$MAIN"))[0] + env.subst("$PROGSUFFIX"))
env.Append(DEP = os.path.splitext(env.subst("$EXE"))[0] + ".dep")

#print("EXE:", env["EXE"])
#print("DEP:", env["DEP"])

#------------------------------------------------------------------------------

env.Append(DFLAGS = [
        "-O",
        "-g",
        "-w",
        "-debug",
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

blob = env.BLOB(
    "$OUTDIR/BLOB.zip",
    findfiles(*env["BLOBFILES"]),
    ARCHIVEROOT = "$ENGINE/../"
)

#------------------------------------------------------------------------------

def PhonyTarget(env, target, requires, action):
    phony = env.Alias(target, None, action)
    env.AlwaysBuild(phony)
    env.Requires(phony, requires)
    #env.Requires(env.AlwaysBuild(env.Alias(target, None, action)), requires)

#------------------------------------------------------------------------------
# Create dependencies for scons
#------------------------------------------------------------------------------

env.Execute(Mkdir("$OUTDIR"))
env.Execute("rdmd --makedepend -of$EXE $DFLAGS $ROOTDIR/$MAIN > $DEP")
env.ParseDepends("$DEP")

#------------------------------------------------------------------------------

exe = env.Command(
    "$EXE", 
    None,
    "rdmd -of$TARGET --build-only $DFLAGS $ROOTDIR/$MAIN"
)

env.Depends(exe, blob)

PhonyTarget(
    env,
    "run",
    exe,
    lambda target, source, env: os.system(env.subst("$EXE"))
)

