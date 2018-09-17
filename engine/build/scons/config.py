###############################################################################
#
# SCons file to configure build environment
#
###############################################################################

Import("*")

env.SConscript("setup.py", "env")

###############################################################################
###############################################################################

#print(env["ENV"]["PATH"])
env["LIBPATH"] = env.Dir("$ENGINE/../local/lib").abspath
print(env["LIBPATH"])
print(env["ENV"]["PATH"])

#------------------------------------------------------------------------------

conf = Configure(env)
conf.CheckProg("dmd")
print(env.WhereIs("lua53", env["ENV"]["PATH"]))
conf.CheckLib('lua5.3')
conf.CheckLib('SDL2')
conf.CheckLib('SDL2_image')
conf.CheckLib('SDL2_ttf')
conf.CheckLib('assimp')
#print(conf.CheckLib('gl'))
conf.Finish()

