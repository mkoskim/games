###############################################################################
#
# SCons file to configure build environment
#
###############################################################################

Import("*")

env.SConscript("setup.py", "env")

###############################################################################
###############################################################################

#env["ENV"]["LD_LIBRARY_PATH"] = env["ENV"]["PATH"]

#print(env["ENV"]["PATH"])
#print(env["ENV"]["LD_LIBRARY_PATH"])

#env["LIBPATH"] = env.Dir("$ENGINE/../local/lib").abspath
#print(env["LIBPATH"])
#print(env["ENV"]["PATH"])

#------------------------------------------------------------------------------

conf = Configure(env)
#conf.CheckProg("git")

conf.CheckProg("dmd")
conf.CheckLib('opengl32')

conf.CheckLib('SDL2')
#conf.CheckLib('SDL2_image')
#conf.CheckLib('png')
#conf.CheckLib('jpg')
#conf.CheckLib('SDL2_ttf')
#conf.CheckLib('freetype')

#conf.CheckLib('assimp')
#conf.CheckLib('lua5.3')

conf.Finish()

