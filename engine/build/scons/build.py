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
        print("Scanning:", env.subst(root))
        for dir, subdirs, files in os.walk(env.subst("$ROOTDIR/" + root)):
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

env["BUILDERS"]["BLOB"] = Builder(action = zipdir, suffix = '.zip')

###############################################################################
#
# Setting environment
#
###############################################################################

#------------------------------------------------------------------------------
# Derived variables
#------------------------------------------------------------------------------

env["ROOTDIR"] = env.Dir("#").abspath
env["OUTDIR"]  = "$ROOTDIR/bin/"
env["EXE"]     = os.path.splitext(env.subst("$OUTDIR/$MAIN"))[0] + env.subst("$PROGSUFFIX")

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

def PhonyTarget(env, target, requires, action):
    phony = env.Alias(target, None, action)
    env.AlwaysBuild(phony)
    env.Requires(phony, requires)

#------------------------------------------------------------------------------
# Create dependencies for scons
#------------------------------------------------------------------------------

def GetDependencies(env, prog, main):
    print("Resolving dependencies:", env.subst(main))

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

###############################################################################
#
# Targets
#
###############################################################################

blob = env.BLOB(
    "$OUTDIR/BLOB.zip",
    findfiles(*env["BLOBFILES"]),
    env
)

exe = env.Command(
    "$EXE",
    GetDependencies(env, "$EXE", "$ROOTDIR/$MAIN") + [blob],
    "rdmd -of$TARGET --build-only $DFLAGS $ROOTDIR/$MAIN"
)

PhonyTarget(
    env,
    "run",
    exe,
    lambda target, source, env: os.system(env.subst("$EXE"))
)

PhonyTarget(
    env,
    "logger",
    None,
    lambda target, source, env: os.system(env.subst("$ENGINE/build/logger.py &"))
)

