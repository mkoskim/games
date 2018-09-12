//*****************************************************************************
//
// Render core file.
//
//*****************************************************************************

module engine.render;

//-----------------------------------------------------------------------------

public import engine.gpu;

import engine.game.instance;
import engine.gpu.util;

import std.string;
import std.array;

//*****************************************************************************
//
// Initialization hook, called when OpenGL context has been created and
// libraries (derelict) has been reloaded. This function sets up some
// global OpenGL parameters to fit to the rendering engine.
//
//*****************************************************************************

void init()
{
    //-------------------------------------------------------------------------

    checkExtensions();
    checkGPUCapabilities();

    //-------------------------------------------------------------------------
    // Clear error flags
    //-------------------------------------------------------------------------

    while(glGetError() != GL_NO_ERROR) {}

    //-------------------------------------------------------------------------

    checkgl!glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    checkgl!glPixelStorei(GL_PACK_ALIGNMENT, 1);

    //-------------------------------------------------------------------------

    screen.fb.bind();
    screen.fb.clear();
}

//*****************************************************************************
//
// Start rendering cycle. For convenience, we should have function to call
// when rendering is done... But that comes later.
//
//*****************************************************************************

void start()
{
    screen.fb.bind();
    //checkgl!glViewport(0, 0, screen.width, screen.height);
    //checkgl!glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

/*
void flush()
{
    checkgl!glFinish();
}
*/

//*****************************************************************************
//
// Check GPU capabilities
// 
//*****************************************************************************

private void checkGPUCapabilities()
{
    auto getInt(GLenum what)
    {
        GLint result;
        glGetIntegerv(what, &result);
        return result;
    }
    
    /*
    writefln("GPU Capablities");
    writefln("- Texture units..............: %d", getInt(GL_MAX_TEXTURE_IMAGE_UNITS));
    writefln("- Max. combined texture units: %d", getInt(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS));
    writefln("- Max. vertex texture units..: %d", getInt(GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS));

    writefln("- Max. uniform locations.....: %d", getInt(GL_MAX_UNIFORM_LOCATIONS));

    writefln("- Max. uniform vectors.......: %d", getInt(GL_MAX_FRAGMENT_UNIFORM_VECTORS));
    writefln("- Max. vertex uniform vectors: %d", getInt(GL_MAX_VERTEX_UNIFORM_VECTORS));

    writefln("- Max. varying vectors.......: %d", getInt(GL_MAX_VARYING_VECTORS));
    
    writefln("- Max. vertex attributes.....: %d", getInt(GL_MAX_VERTEX_ATTRIBS));
    */
}

//*****************************************************************************
//
// Extension queries: I am very interested in what versions of OpenGL I
// am using, and what extensions I have available. Currently, I am
// asking OpenGL version 3.3 context to get GLSL 330.
//
// For more info about versions and what extensions they ate, see:
//
//      https://www.opengl.org/wiki/History_of_OpenGL
//
//*****************************************************************************

private void checkExtensions()
{
    //writeln("OpenGL extension queries:");

    bool[string] getExtensions()
    {
        bool[string] lookup;
        if(screen.glversion < 3.0)
        {
            string[] list = std.array.split(to!string(checkgl!glGetString(GL_EXTENSIONS)));
            foreach(key; list) lookup[key] = true;
        } else {
            GLint n;
            checkgl!glGetIntegerv(GL_NUM_EXTENSIONS, &n);
            for(int i = 0; i < n; i++) {
                lookup[to!string(glGetStringi(GL_EXTENSIONS, i))] = true;
            }            
        }
        return lookup;
    }

    bool[string] extensions = getExtensions();

    bool hasExtension(string key)
    {
        return (key in extensions) ? true : false;
    }

    void nocheck(string extension, float coreat) {}

    bool check(string extension, float coreat)
    {
        bool report(bool result, string msg)
        {
            //writefln("- %-4s: %s", msg, extension);
            return result;
        }
        
        /*
        if(coreat && screen.glversion >= coreat)
        {
            return report(true, "Core");
        }
        */
        bool status = hasExtension(extension);
        return report(status, (status ? "Yes" : "No"));
    }

    void require(string extension, float coreat)
    {
        ERRORIF(
            check(extension, coreat),
            format("OpenGL extension required: %s", extension)
        );
    }

    //-------------------------------------------------------------------------
    // GLSL version     OpenGL
    // 120              2.1
    // ---              3.0
    // 140              3.1
    // 150              3.2
    // 330              3.3
    //-------------------------------------------------------------------------

    //-------------------------------------------------------------------------
    // VAOs and framebuffers - this is crucial.
    //-------------------------------------------------------------------------

    require("GL_ARB_vertex_array_object", 3.0);
    require("GL_ARB_framebuffer_object", 3.0);

    //-------------------------------------------------------------------------
    // Do we have texture storage for mipmaps?
    //-------------------------------------------------------------------------

    check("GL_ARB_texture_storage", 4.2);

    //-------------------------------------------------------------------------
    // Plan is to use instanced rendering... Do we have it?
    //-------------------------------------------------------------------------

    check("GL_ARB_draw_instanced", 3.1);
    check("GL_ARB_instanced_arrays", 3.3);

    //-------------------------------------------------------------------------
    // Array Textures: The description is interesting...
    //      https://www.opengl.org/wiki/Array_Texture
    //-------------------------------------------------------------------------

    check("GL_EXT_texture_array", 3.0);

    //-------------------------------------------------------------------------
    // Do we have uniform buffers? Do we find any use for them?
    //      https://www.opengl.org/wiki/Interface_Block_(GLSL)
    //-------------------------------------------------------------------------

    check("GL_ARB_uniform_buffer_object", 3.1);
    check("GL_ARB_shader_storage_buffer_object", 3.1);

    //-------------------------------------------------------------------------
    // Do we have shader subroutines? Do we have geometry shader?
    //-------------------------------------------------------------------------

    check("GL_ARB_shader_subroutine", 4.0);
    nocheck("GL_ARB_geometry_shader4", 3.2);

    //-------------------------------------------------------------------------
    // Interfacing to GPU programs
    //-------------------------------------------------------------------------

    check("GL_ARB_program_interface_query", 4.3);

    //-------------------------------------------------------------------------
    // Explicit locations for attributes? Using this needs modifications
    // at GLSL side:
    // https://www.opengl.org/registry/specs/ARB/explicit_attrib_location.txt
    //-------------------------------------------------------------------------

    check("GL_ARB_explicit_attrib_location", 3.3);
    check("GL_ARB_explicit_uniform_location", 4.3);

    //-------------------------------------------------------------------------
    // Do we have separate attrib binding? Can we set up vertex array without
    // binding it and buffers first?
    //-------------------------------------------------------------------------

    check("GL_ARB_vertex_attrib_binding", 4.3);
    check("GL_ARB_direct_state_access", 4.4);
    
    //-------------------------------------------------------------------------
    // Primitive restart might be a nice feature:
    //      https://www.opengl.org/wiki/Vertex_Rendering#Primitive_Restart
    //-------------------------------------------------------------------------

    check("GL_NV_primitive_restart", 3.1);

    //-------------------------------------------------------------------------
    // Texture swizzling might be useful for some features:
    //      https://www.opengl.org/wiki/Texture#Swizzle_mask
    //-------------------------------------------------------------------------

    check("GL_ARB_texture_swizzle", 3.3);

    //-------------------------------------------------------------------------
    // Could we store skeletal animation transforms to buffer texture?
    //      https://www.opengl.org/wiki/Buffer_Texture
    //-------------------------------------------------------------------------

    check("GL_ARB_texture_buffer_object", 3.0);
    check("GL_EXT_texture_buffer_object", 3.0);

    //-------------------------------------------------------------------------
    // Performance timers - need I say more?
    //      https://www.opengl.org/wiki/Query_Object#Timer_queries
    //-------------------------------------------------------------------------

    check("GL_ARB_timer_query", 3.3);

    //-------------------------------------------------------------------------
    // Image Load/Store for order-independent transparency?!?
    //      https://www.opengl.org/wiki/Image_Load_Store#Image_size
    //-------------------------------------------------------------------------

    check("GL_ARB_shader_image_size", 4.3);
    check("GL_ARB_shader_image_load_store", 4.2);
    check("GL_EXT_shader_image_load_store", 4.2);

    //-------------------------------------------------------------------------
    // Do we have GL_INT_2_10_10_10_REV? Do we find any use for it?
    //-------------------------------------------------------------------------

    check("GL_ARB_vertex_type_2_10_10_10_rev", 3.3);

    //-------------------------------------------------------------------------
}

