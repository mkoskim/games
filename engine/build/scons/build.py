###############################################################################
#
# Building projects
#
###############################################################################

import os
Import("*")

#------------------------------------------------------------------------------
# Helpers
#------------------------------------------------------------------------------

def exename(name):
    return os.path.splitext(name)[0] + env.subst("$PROGSUFFIX")

def dsrcname(name):
    return os.path.splitext(name)[0] + ".d"

###############################################################################
#
# Setting environment
#
###############################################################################

env.SConscript("setup.py", "env")

env["ROOTDIR"] = env.Dir("#").abspath
env["OUTDIR"]  = "$ROOTDIR/bin/"
env["EXE"]     = exename(env.subst("$OUTDIR/$MAIN"))

###############################################################################
#
# Creating ZIP archives
#
###############################################################################

#------------------------------------------------------------------------------
# Find files in directory trees
#------------------------------------------------------------------------------

def findfiles(env, dirs):
    result = []
    for root in dirs:
        root = env.subst("$ROOTDIR/" + root)
        print("Scanning:", root)
        for dir, subdirs, files in os.walk(root):
            for file in files:
                result.append(dir + "/" + file)
    return result

#------------------------------------------------------------------------------
# Zipping source (files) to archive (target)
#------------------------------------------------------------------------------

def zipdir(target, source, env):
    import zipfile

    tgtname = target[0].name
    target  = target[0].abspath

    zipdir = os.path.dirname(env.subst(target))
    if not os.path.exists(zipdir):
        os.mkdir(zipdir)

    zipf = zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED)

    for file in source:
        archivename = os.path.relpath(file.abspath, env["ROOTDIR"])
        print(tgtname, "<=", archivename)
        zipf.write(file.abspath, arcname = archivename)

    zipf.close()

env["BUILDERS"]["BLOB"] = Builder(
    action = zipdir,
    #emitter = BLOB_Emitter,
)

###############################################################################
#
# D compiling
#
###############################################################################

#------------------------------------------------------------------------------
# Create dependencies for scons
#------------------------------------------------------------------------------

def GetDependencies(env, prog, main):
    #print("Resolving dependencies:", env.subst(main))

    from subprocess import PIPE, STDOUT, check_output, CalledProcessError
    try:
        stdout = check_output(
            env.subst("rdmd --makedepend -of{} $DFLAGS {}".format(prog, main)),
            shell = True,
            universal_newlines = True,
        )
    except CalledProcessError as e:
        print(e.output)
        exit(e.returncode)

    lines = []
    for line in stdout.splitlines():
        line = line.strip()
        if len(lines) and lines[-1].endswith("\\"):
            lines[-1] = lines[-1][:-1].strip() + " " + line
        else:
            if len(line): lines.append(line)

    target, sources = lines[0].split(": ", 1)

    if target != env.subst(prog):
        print("Coudln't resolve dependencies.")
        exit(-1)
    return sources.split()

def RDMD_Emitter(target, source, env):

    exe = target[0].abspath

    if not len(source):
        main = dsrcname(exe)
    else:
        main, source = source[0].abspath, source[1:]

    return target, GetDependencies(env, exe, main) + source

#------------------------------------------------------------------------------
# RDMD builder
#------------------------------------------------------------------------------

env["BUILDERS"]["RDMD"] = Builder(
    action = "rdmd -of$TARGET --build-only $DFLAGS $ROOTDIR/$MAIN",
    emitter = RDMD_Emitter,
)

#------------------------------------------------------------------------------
# Flags for building
#------------------------------------------------------------------------------

env.Append(DFLAGS = [
        "-O",
        "-g",
        "-w",
        "-debug",
        "-color=off",
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

###############################################################################
#
# Some helpers
#
###############################################################################

def PhonyTarget(env, target, requires, action):
    phony = env.Alias(target, None, action)
    env.AlwaysBuild(phony)
    env.Requires(phony, requires)

###############################################################################
#
# Targets
#
###############################################################################


PhonyTarget(env, "logger", None, lambda target, source, env: os.system(env.subst("$ENGINE/build/logger.py &")))

#------------------------------------------------------------------------------
# If logger is only target, no need to add others (which cause dependency
# generation).
#------------------------------------------------------------------------------

if " ".join(COMMAND_LINE_TARGETS) != "logger":

    blob = env.BLOB(
        "$OUTDIR/BLOB.zip",
        findfiles(env, env["BLOBFILES"])
    )

    exe = env.RDMD("$EXE", ["$ROOTDIR/$MAIN", blob])

    PhonyTarget(env, "run", exe, lambda target, source, env: os.system(env.subst("$EXE")))

