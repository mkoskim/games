###############################################################################
#
#
#
###############################################################################

#------------------------------------------------------------------------------

import os, platform
from SCons.Builder import Builder

print("Platform:", platform.system())

#------------------------------------------------------------------------------

def findfiles(*dirs):
    result = []
    for root in dirs:
        for dir, subdirs, files in os.walk(root):
            for file in files:
                result.append(dir + "/" + file)
    return result

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

def SetEnv(env):
    env["BUILDERS"]["BLOB"] = Builder(action = zipdir, suffix = '.zip')
    env["DFLAGS"] = [
        "-Jbin/",
        "-I$ENGINE/../",
        "-I$ENGINE/libs/DerelictASSIMP3/source/",
        "-I$ENGINE/libs/DerelictGL3/source/",
        "-I$ENGINE/libs/DerelictLua/source/",
        "-I$ENGINE/libs/DerelictSDL2/source/",
        "-I$ENGINE/libs/DerelictUtil/source/",
        "-I$ENGINE/libs/gl3n",
    ]
