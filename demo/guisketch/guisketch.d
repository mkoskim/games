//*****************************************************************************
//
// GUI sketching
//
//*****************************************************************************

import engine;

import std.stdio;

//-----------------------------------------------------------------------------
//
// What would we like to have...
//
// - Layouts: no need to set coordinates nor dimensions
// - Simple keyboard/controller traversal
//
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------

void main()
{
    game.init();
    
    auto actors = new game.FiberQueue();

    //-------------------------------------------------------------------------

    vec4[char] colorchart = [
        ' ': vec4(0, 0, 0, 0),
        'x': vec4(0.75, 0.75, 0.75, 1),
        '#': vec4(0.25, 0.25, 0.25, 1),
        '.': vec4(0.50, 0.50, 0.50, 1),
    ];

    string[] btnframe = [
        "xxxx" "xxxx" "xxxx",
        "xxxx" "xxxx" "xxx#",
        "xxxx" "xxxx" "xx##",
        "xxxx" "xxxx" "x###",

        "xxxx" "    " "####",
        "xxxx" "    " "####",
        "xxxx" "    " "####",
        "xxxx" "    " "####",

        "xxxx" "####" "####",
        "xxx#" "####" "####",
        "xx##" "####" "####",
        "x###" "####" "####",
    ];

    string[] grpframe = [
        "...." "...." "....",
        "...." "...." "....",
        "..##" "####" "##..",
        "..# " "    " " x..",

        "..# " "    " " x..",
        "..# " "    " " x..",
        "..# " "    " " x..",
        "..# " "    " " x..",

        "..# " "    " " x..",
        "..#x" "xxxx" "xx..",
        "...." "...." "....",
        "...." "...." "....",
    ];

    //-------------------------------------------------------------------------

    auto textures = [
        Texture.upload(Bitmap.splitSheet(btnframe, colorchart, 4, 4)),
        Texture.upload(Bitmap.splitSheet(grpframe, colorchart, 4, 4)),
    ];

    //auto box = new Frame(textures, new Box(vec4(1, 1, 0, 1), 32, 32));

    class IconBox : Frame
    {
        this(vec4 color) {
            super(textures[1], new Box(color, 32, 32));
        }
    }

    auto canvas = new Canvas();

    auto row = new Grid(
        new IconBox(vec4(1, 1, 0, 1)),
        new IconBox(vec4(0, 1, 1, 1)),
        null,
        new IconBox(vec4(0, 1, 0, 1)),
        new IconBox(vec4(0, 0, 1, 1)),
        
        /*
        new Box(vec4(1, 1, 0, 1), 32, 32),
        new Box(vec4(0, 1, 1, 1), 32, 32),
        null,
        new Box(vec4(0, 1, 0, 1), 32, 32),
        new Box(vec4(1, 0, 1, 1), 32, 32)
        */
    );
    
    canvas.add(new Anchor(vec2(0.95, 0.95), new Frame(textures[0], row)));

    //-------------------------------------------------------------------------

    actors.reportperf;

    //-------------------------------------------------------------------------

    simple.gameloop(
        &canvas.draw,
        actors
    );
}

