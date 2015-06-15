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
        "xxx." "...." ".###",

        "xxx." "...." ".###",
        "xxx." "...." ".###",
        "xxx." "...." ".###",
        "xxx." "...." ".###",

        "xxx." "...." ".###",
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
        gui.Texture.upload(Bitmap.splitSheet(btnframe, colorchart, 4, 4)),
        gui.Texture.upload(Bitmap.splitSheet(grpframe, colorchart, 4, 4)),
    ];

    //auto box = new Frame(textures, new Box(vec4(1, 1, 0, 1), 32, 32));

    /*
    class IconBox : gui.Widget
    {
        this(vec4 color) {
            super(textures[1], new gui.Box(color, 32, 32));
        }
    }

    class Button : gui.Widget
    {
        gui.Label label;
        
        this(string text) {
            this.label = new gui.Label(text, vec4(0, 0, 0, 1));
            super(textures[0], new gui.Anchor(0.5, 0.5, label));
        }        
    }
    */

    /*
    auto row = new gui.Grid(
        new IconBox(vec4(1, 1, 0, 1)),
        new IconBox(vec4(0, 1, 1, 1)),
        null,
        new IconBox(vec4(0, 1, 0, 1)),
        new IconBox(vec4(0, 0, 1, 1)),        
    );
    */
    
    /*
    auto row = new gui.Grid(
        new Button("Continue"), null,
        new Button("New game"), null,
        new Button("Options"), null,
        new Button("Quit")
    );
    */

    auto row = new gui.Grid(
        new gui.Label("Continue", vec4(1, 0, 0, 1)), null,
        new gui.Label("New game", vec4(1, 0, 0, 1)), null,
        new gui.Label("Options", vec4(1, 0, 0, 1)), null,
        new gui.Label("Quit", vec4(1, 0, 0, 1))
    );
    
    auto canvas = new gui.Canvas();

    canvas.add(
        new gui.Anchor(
            vec2(0.50, 0.50),
            //new gui.Frame(textures[0], row)
            row
        )
    );

    //btn.label.text = "Yeah!";

    //-------------------------------------------------------------------------

    actors.reportperf;

    //-------------------------------------------------------------------------

    simple.gameloop(
        &canvas.draw,
        actors
    );
}

