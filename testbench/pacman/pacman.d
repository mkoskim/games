//*****************************************************************************
//
// Basic Pacman
//
//*****************************************************************************

import std.stdio;
import std.string;

import engine;

//-----------------------------------------------------------------------------
// Unit length tells how large is one maze block (1 x 1) at screen.
//-----------------------------------------------------------------------------

const int unitlength = 18;

//*****************************************************************************
//
// main
//
//*****************************************************************************

render.Shader shader;

void main()
{
    //-------------------------------------------------------------------------
    // Initialize window for 32x32 "units", with some space at y direction for
    // HUD texts. Set default targeted FPS to 50.
    //-------------------------------------------------------------------------

    game.init(32 * unitlength, 20 + 32 * unitlength + 12);
    game.fps = 50;

    //-------------------------------------------------------------------------

    shader = render.shaders.Default2D.create();
    //auto shader = new render.shaders.Blanko();

    for(;;)
    {
        game.Track.rungc();
        string maze = choosemaze();
        if(!maze) break;

        game.Track.rungc();
        play(maze);
    }
}

//*****************************************************************************
//
// Start screen: choose maze
//
//*****************************************************************************

string choosemaze()
{
    return "1.txt";
}

//*****************************************************************************
//*****************************************************************************

//*****************************************************************************
//
// Game: First we load the maze, then we play.
//
//*****************************************************************************

void play(string mazename)
{
    //-------------------------------------------------------------------------
    //
    // Load maze. Mazes are stored as two-dimensional character arrays, see
    // files in data/mazes/*. We split the content to lines, and
    // then go through it character by character to create graphical
    // representation. The splitted array is kept for collision detection.
    //
    //-------------------------------------------------------------------------

    char[][] grid;

    {
        string maze = cast(string)blob.extract("data/mazes/" ~ mazename);

        if(countchars(maze, "@") != 1)
        {
            writefln("data/mazes/%s: Invalid number of players.", mazename);
            return;
        }

        foreach(line; maze.splitLines())
        {
            if(line.length) grid ~= line.dup;
        }
    }

    ulong width = grid[0].length;
    ulong height = grid.length;

    //-------------------------------------------------------------------------
    // Create view and adjust maze to center of window.
    //-------------------------------------------------------------------------

    auto cam = render.Camera.topleft2D(unitlength);

    cam.grip.pos -= vec3(
        (cast(int)game.screen.width - cast(int)width*unitlength) / (2.0 * unitlength),
        (cast(int)game.screen.height - cast(int)height*unitlength) / (2.0 * unitlength),
        0
    );

    auto scene = new render.UnbufferedRender(
        cam,
        render.State.Default2D()
    );
    
    //-------------------------------------------------------------------------
    //
    // Layers: There is one trick here for visual purpose. In fact, we draw
    // clean routes with black, over a blue background. This choice was made
    // after complex attempts to try to "thin" walls based on what they are
    // neighboring.
    //
    // Other than this (maze and background layers), the rest are pretty
    // self-explanatory: layers for food, doors and mobs.
    //
    // Creating different batches for different game objects does not only
    // serve for determining drawing order, but it can also help collision
    // detection (that is, each group is also collision group).
    //
    //-------------------------------------------------------------------------

    auto background = scene.addbatch();
    auto path  = scene.addbatch();
    auto doors = scene.addbatch();
    auto foods = scene.addbatch();
    auto mobs  = scene.addbatch();

    //-------------------------------------------------------------------------
    // Shapes (Models: mesh + material)
    //-------------------------------------------------------------------------
    
    render.Mesh
        rect1x1  = geom.rect(1, 1),
        rect2x2  = geom.rect(1.66, 1.66),
        foodmesh = geom.rect(0.25, 0.25),
        doormesh = geom.rect(1.66, 0.33);

    auto doormat = new render.Material(0.7, 0.7, 0.7);
    auto pathmat = new render.Material(0, 0, 0);
    auto wallmat = new render.Material(0.3, 0.3, 0.6);
    auto foodmat = new render.Material(0.6, 0.6, 0.2);

    auto mBG   = background.upload(geom.rect(width, height), wallmat);
    auto mDoor = doors.upload(doormesh, doormat);
    auto mPath = path.upload(rect2x2, pathmat);
    auto mFood = foods.upload(foodmesh, foodmat);

    //-------------------------------------------------------------------------
    // Adding models to scene takes them automatically to the layer
    // (Batch), where the shape is created.
    //-------------------------------------------------------------------------

    scene.add(0, 0, mBG);

    //-------------------------------------------------------------------------
    // Create sprite shapes (rectangular meshes) from sprite sheet. Organize
    // shapes so that they are easily referenced from code.
    //-------------------------------------------------------------------------
    
    auto mMob = mobs.upload(rect2x2, cast(render.Material)(null));
    
    auto mMobAnim = function render.Model[][][](render.Batch batch)
    {
        auto sheet = render.Model.sheet(
            batch,
            render.Texture.Loader.Default("data/images/ChomperSprites.png"),
            32, 32,
            1.66, 1.66
        );
        return
            [[
                [sheet[2][10], sheet[2][11]],
                [sheet[0][10], sheet[0][11]],
                [sheet[3][10], sheet[3][11]],
                [sheet[1][10], sheet[1][11]],
            ],[
                [sheet[2][0], sheet[2][1]],
                [sheet[0][0], sheet[0][1]],
                [sheet[3][0], sheet[3][1]],
                [sheet[1][0], sheet[1][1]],
            ],[
                [sheet[2][2], sheet[2][3]],
                [sheet[0][2], sheet[0][3]],
                [sheet[3][2], sheet[3][3]],
                [sheet[1][2], sheet[1][3]],
            ],[
                [sheet[2][4], sheet[2][5]],
                [sheet[0][4], sheet[0][5]],
                [sheet[3][4], sheet[3][5]],
                [sheet[1][4], sheet[1][5]],
            ],[
                [sheet[2][6], sheet[2][7]],
                [sheet[0][6], sheet[0][7]],
                [sheet[3][6], sheet[3][7]],
                [sheet[1][6], sheet[1][7]],
            ]];
    }(mobs);

    //*************************************************************************
    //
    // Navigation map (incomplete). In pacman like game, actors are only
    // allowed to move from one empty location to neighboring empty location.
    //
    //*************************************************************************

    enum Head { left, right, up, down, none }

    class Node
    {
        Node[Head] route;
    }

    //*************************************************************************
    //
    // Actors (player and ghosts)
    //
    //*************************************************************************

    vec3[Head] directions = [
        Head.left:  vec3(-1,  0, 0),
        Head.right: vec3(+1,  0, 0),
        Head.up:    vec3( 0, -1, 0),
        Head.down:  vec3( 0, +1, 0)
    ]; 

    //-------------------------------------------------------------------------

    abstract class Actor : game.Fiber
    {
        ulong num;
        render.Node sprite;

        this(render.Node sprite, ulong num)
        {
            super(&run);
            this.sprite = sprite;
            this.num = num;
            setshape();
        }

        void setshape(Head current = Head.up)
        {
            int animframe = (game.frame >> 2) & 1;
            sprite.model = mMobAnim[num][current][animframe];
        }
    
        bool checkgrid(Head next, string walls = "#=")
        {
            vec3 p = sprite.grip.pos + directions[next];
            return !inPattern(grid[cast(int)p.y][cast(int)p.x], walls);
        }

        static const int steps = 10;

        void step(Head next)
        {
            vec3 delta = directions[next] * (1.0/steps);
            sprite.grip.pos += delta;
        }

    }

    //-------------------------------------------------------------------------

    class Player : Actor
    {
        int points = 0;

        this(render.Node sprite) { super(sprite, 0); }

        void checkfood()
        {
            foreach(food; foods.nodes)
            {
                if(sprite.distance(food) < 0.5)
                {
                    foods.remove(food);
                    points += 10;
                }
            }
        }

        Head next = Head.none;

        void checkinput()
        {
            bool isdown(uint keycode, uint joycode) {
                return game.keydown(keycode) || (game.joysticks.length && game.joysticks[0].buttons[joycode]);
            }

            if(isdown(SDLK_LEFT, game.JOY.BTN.LS_LEFT))         next = Head.left;
            else if(isdown(SDLK_RIGHT, game.JOY.BTN.LS_RIGHT)) next = Head.right;
            else if(isdown(SDLK_UP, game.JOY.BTN.LS_UP))       next = Head.up;
            else if(isdown(SDLK_DOWN, game.JOY.BTN.LS_DOWN))   next = Head.down;
        }

        override void run()
        {
            Head current = Head.left;
            int moving = 0;

            for(;;)
            {
                checkinput();
                checkfood();

                if(moving)
                {
                    step(current);
                    moving--;
                }

                if(!moving)
                {
                    if(next != Head.none && checkgrid(next, "#=-")) current = next;
                    if(checkgrid(current, "#=-")) moving = steps;
                }

                setshape(current);
                nextframe();
            }
        }
    }

    //-------------------------------------------------------------------------

    class Ghost : Actor
    {
        this(render.Node sprite, ulong num)
        {
            super(sprite, (num % 4) + 1);
        }

        //---------------------------------------------------------------------
        // AI
        //---------------------------------------------------------------------
        
        import std.random;
        import std.algorithm: filter;

        Head[] turndirs(Head current)
        {
            switch(current)
            {
                case Head.up:
                case Head.down:  return [Head.left, Head.right];
                case Head.left:
                case Head.right: return [Head.up, Head.down];
                default: break;
            }
            return [];
        }

        Head[] valid(Head[] directions)
        {
            return std.array.array(directions.filter!(choice => checkgrid(choice)));
        }

        Head pick(Head[] choices)
        {
            return choices[uniform(0, choices.length)];
        }

        Head anyvalid()
        {
            return pick(valid([Head.up, Head.down, Head.left, Head.right]));
        }

        //---------------------------------------------------------------------

        override void run()
        {
            Head current = anyvalid();

            for(;;)
            {
                bool currentvalid = checkgrid(current);

                Head[] choices = valid(turndirs(current));
                if(choices.length && (currentvalid ? dice(50, 50) : 1))
                {
                    current = pick(choices);
                }
                else if(!currentvalid)
                {
                    current = anyvalid();
                }

                for(int i = steps; i--; nextframe())
                {
                    step(current);
                    setshape(current);
                }
            }
        }
    }

    //-------------------------------------------------------------------------

    auto actors = new game.FiberQueue();

    Player player;

    //*************************************************************************
    //
    // Functions to add shapes to layers from maze data
    //
    //*************************************************************************

    void add_wall(size_t x, size_t y) {
    }

    void add_empty(size_t x, size_t y) {
        scene.add(x - 0.33, y - 0.33, mPath);
        grid[y][x] = ' ';
    }

    void add_door(size_t x, size_t y) {
        //add_empty(x, y);
        scene.add(x - 0.33, y + 0.33, mDoor);
    }

    void add_food(size_t x, size_t y) {
        add_empty(x, y);
        scene.add(x + 0.5, y + 0.5, mFood);
    }

    void add_ghost(size_t x, size_t y) {
        add_empty(x, y);
        auto sprite = scene.add(render.Grip.movable(x + 0.5, y + 0.5), mMob);
        actors.add(new Ghost(sprite, mobs.length));
    }

    void add_player(size_t x, size_t y) {
        add_empty(x, y);
        auto sprite = scene.add(render.Grip.movable(x + 0.5, y + 0.5), mMob);
        player = new Player(sprite);
    }

    //-------------------------------------------------------------------------

    foreach(y, line; grid)
    {
        foreach(x, c; line)
        {
            switch(c)
            {
                case '\'':
                case ' ': add_empty(x, y); break;
                case '.': add_food(x, y); break;
                case '=': add_door(x, y); break;
                case '@': add_player(x, y); break;
                case 'A': add_ghost(x, y); break;
                case '#': add_wall(x,y); break;

                default: break;
            }
        }
    }

    //*************************************************************************
    //
    // GUI
    //
    //*************************************************************************

    auto hud = new gui.Canvas();

    //-------------------------------------------------------------------------

    gui.Label.Style.add(null,
        Font.load("engine/stock/fonts/liberation/LiberationMono-Regular.ttf", 12),
        vec4(0.9, 0.9, 0.9, 1)
    );

    gui.Label.Style.add("score", 
        Font.load("engine/stock/fonts/Digital-7/digital-7__mono_.ttf", 26),
        vec4(1, 1, 1, 1)
    );

    hud.add(
        new gui.Position(2, 2,
            new gui.Grid(
                gui.Label["score"]("SCORE: "),
                gui.Label["score"]((){ return format("%06d", player.points); }),
            )
        ),
        new gui.Anchor(0, 1,
            gui.Label[null](() { return game.Profile.info(); })
        ),
    );

    //-------------------------------------------------------------------------

    actors.reportperf();

    //*************************************************************************
    //
    // Game loop(s)
    //
    //*************************************************************************

    void drawscreen()
    {
        scene.draw();
        hud.draw();
    }

    //-------------------------------------------------------------------------
    // Wait user to press key: simple.gameloop breaks the loop, if event
    // processing function returns false. We create anonymous function to
    // process incoming events.
    //-------------------------------------------------------------------------

    game.Track.rungc();

    simple.gameloop(
        &drawscreen,
        actors,
        (SDL_Event* event) {
            switch(event.type) {
                case SDL_JOYBUTTONDOWN:
                case SDL_KEYDOWN: return false;
                default: return true;
            }
        }
    );

    //-------------------------------------------------------------------------
    // Open doors and activate player: "-" means in a grid a wall that is
    // transparent for ghosts, but player can't pass it.
    //-------------------------------------------------------------------------

    foreach(y, line; grid) foreach(x, c; line) if(c == '=') grid[y][x] = '-';

    //doormat.color = vec4(0, 0, 0, 1);
    actors.add(player);

    //-------------------------------------------------------------------------
    // Game loop
    //-------------------------------------------------------------------------

    simple.gameloop(&drawscreen, actors);
}

