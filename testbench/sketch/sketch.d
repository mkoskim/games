//*****************************************************************************
//
// General 'sketching' project to develop new features.
//
//*****************************************************************************

import engine;

//-----------------------------------------------------------------------------

static import std.file;
import std.stdio;
import std.string;
import std.conv: to;

//-----------------------------------------------------------------------------

void main()
{
    //SDL_sketching();
    engine_sketching();
}

//*****************************************************************************
//
// Engine sketching
//
//*****************************************************************************

void engine_sketching()
{
    game.init();

    auto layer = new render.Layer(
        render.shaders.Lightless3D.create(),
        render.Camera.basic3D(1, 100)
    );

    auto cube = blob.wavefront.loadmesh("engine/stock/mesh/Cube/Cube.obj");
    layer.add(
        vec3(0, 0, -5),
        layer.upload(cube),
        new render.Material(1, 0, 0)
    );

    simple.gameloop(10, &layer.draw, null, null);
}

//*****************************************************************************
//
// Sketching with plain SDL
//
//*****************************************************************************

void SDL_sketching()
{
    import derelict.sdl2.image;

    DerelictSDL2.load();
    DerelictSDL2Image.load();

    SDL_Init(SDL_INIT_VIDEO);
    IMG_Init(IMG_INIT_PNG);

    auto window = SDL_CreateWindow(
        toStringz("Test"),
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        640, 480,
        SDL_WINDOW_SHOWN
    );

    auto ren = SDL_CreateRenderer(window, 0, 0);

    //-------------------------------------------------------------------------

    auto gFont = TTF_OpenFont( "engine/stock/fonts/SourceSansPro/SourceSansPro-Regular.otf", 12 );
    if(!gFont)
    {
        writeln("Error: ", to!string(TTF_GetError()));
        return;
    }

    string str = "Hello, world!";
    SDL_Color color={1,1,1,1};

    auto img = TTF_RenderText_Solid(gFont, str.toStringz, color);

    writeln(img.w, " x ", img.h);

    //-------------------------------------------------------------------------

    SDL_RenderCopy(ren, SDL_CreateTextureFromSurface(ren, img), null, null);
    SDL_RenderPresent(ren);

    for(;;)
    {
        SDL_Event event;
        SDL_WaitEvent(&event);

        if(event.type == SDL_QUIT) break;
    }

    SDL_Quit();
}

