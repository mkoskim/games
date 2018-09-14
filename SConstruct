#------------------------------------------------------------------------------

import os
import platform

print("Platform:", platform.system())

env = Environment(ENV = {"PATH": os.environ["PATH"]})
env["ENGINE"] = "../../engine/"

#------------------------------------------------------------------------------

conf = Configure(env)
conf.CheckProg("dmd")
conf.CheckLib('lua5.3')
conf.CheckLib('SDL2')
conf.CheckLib('SDL2_image')
conf.CheckLib('SDL2_ttf')
conf.CheckLib('SDL2_ttf')
conf.CheckLib('z')
conf.CheckLib('assimp')
#print(conf.CheckLib('gl'))

