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

int unitlength = 18;

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
        string maze = choosemaze();
        if(!maze) break;
        play(maze);
        game.cleantrash();
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

    ulong width = grid[0].length, height = grid.length;

    //-------------------------------------------------------------------------
    // Create view and adjust maze to center of window.
    //-------------------------------------------------------------------------

    auto cam = render.Camera.topleft2D(unitlength);

    cam.grip.pos -= vec3(
        (cast(int)game.screen.width - cast(int)width*unitlength) / (2.0 * unitlength),
        (cast(int)game.screen.height - cast(int)height*unitlength) / (2.0 * unitlength),
        0
    );

    //-------------------------------------------------------------------------
    // Create layers
    //-------------------------------------------------------------------------

    auto maze  = new render.Layer(shader, cam);
    auto doors = new render.Layer(maze);
    auto foods = new render.Layer(maze);
    auto mobs  = new render.Layer(maze);

    auto background = new render.Layer(maze);

    auto mazecolor = new render.Material(0.3, 0.3, 0.6);

    background.add(0, 0, shader.upload(geom.rect(width, height)), mazecolor);

    //*************************************************************************
    //
    // Actors (player and ghosts)
    //
    //*************************************************************************

    enum Head { left, right, up, down, none }

    vec3[Head] directions = [
        Head.left:  vec3(-1,  0, 0),
        Head.right: vec3(+1,  0, 0),
        Head.up:    vec3( 0, -1, 0),
        Head.down:  vec3( 0, +1, 0)
    ]; 

    //-------------------------------------------------------------------------

    auto textures = function render.Texture[][][]()
    {
        auto sheet = render.Texture.loadSheet("data/images/ChomperSprites.png", 32, 32);
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
    }();

    //-------------------------------------------------------------------------

    abstract class Actor : game.Fiber
    {
        render.Instance shape;

        this(render.Instance shape)
        {
            super(&run);
            this.shape = shape;
        }

        bool checkgrid(Head next, string walls = "#=")
        {
            vec3 p = shape.pos + directions[next];
            return !inPattern(grid[cast(int)p.y][cast(int)p.x], walls);
        }

        static const int steps = 10;

        void step(Head next)
        {
            vec3 delta = directions[next] * (1.0/steps);
            shape.pos += delta;
        }

        int animframe() { return (game.frame >> 2) & 1; }
    }

    //-------------------------------------------------------------------------

    class Player : Actor
    {
        Head next = Head.none;
        int points = 0;

        this(render.Instance shape) { super(shape); }

        void checkfood()
        {
            foreach(food; foods.instances.keys)
            {
                if(distance(shape.pos, food.pos) < 0.5)
                {
                    foods.remove(food);
                    points += 10;
                }
            }
        }

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
                shape.shape.material.colormap = textures[0][current][animframe()];

                nextframe();
            }
        }
    }

    Player player;

    //-------------------------------------------------------------------------

    class Ghost : Actor
    {
        ubyte num;

        this(render.Instance shape, ulong num)
        {
            super(shape);
            this.num = num % 4;
        }

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

                shape.shape.material.colormap = textures[num + 1][current][animframe()];
                for(int i = steps; i--; nextframe()) step(current);
            }
        }
    }

    //-------------------------------------------------------------------------

    auto actors = new game.FiberQueue();

    //*************************************************************************
    //
    // Functions to add shapes to layers from maze data
    //
    //*************************************************************************

    render.Shader.VAO
        rect1x1  = shader.upload(geom.rect(1, 1)),
        rect2x2  = shader.upload(geom.rect(1.66, 1.66)),
        foodmesh = shader.upload(geom.rect(0.25, 0.25)),
        actorbox = shader.upload(geom.rect(1.66, 1.66, geom.center)),
        doormesh = shader.upload(geom.rect(1.66, 1));

    auto doormat = new render.Material(0.7, 0.7, 0.7);

    void add_wall(size_t x, size_t y) {
    }

    void add_empty(size_t x, size_t y) {
        maze.add(x - 0.33, y - 0.33, rect2x2, vec4(0, 0, 0, 1));
    }

    void add_door(size_t x, size_t y) {
        //add_empty(x, y);
        doors.add(x - 0.33, y, doormesh, doormat);
    }

    void add_food(size_t x, size_t y) {
        add_empty(x, y);
        foods.add(x + 0.5, y + 0.5, foodmesh, vec4(0.6, 0.6, 0.2, 1));
        grid[y][x] = ' ';
    }

    void add_ghost(size_t x, size_t y) {
        add_empty(x, y);
        auto shape = mobs.add(x + 0.5, y + 0.5, actorbox, new render.Material());
        grid[y][x] = ' ';
        actors.add(new Ghost(shape, mobs.length));
    }

    void add_player(size_t x, size_t y) {
        add_empty(x, y);
        auto shape = mobs.add(x + 0.5, y + 0.5, actorbox, new render.Material());
        grid[y][x] = ' ';
        shape.shape.material.colormap = textures[0][0][0];
        player = new Player(shape);
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

    auto hud = new render.Layer(shader, render.Camera.topleft2D);

    //-------------------------------------------------------------------------

    auto txtPoints = new TextBox(
        hud, 2, 0, "SCORE: %points%",
        Font.load("engine/stock/fonts/Digital-7/digital-7__mono_.ttf", 26)
    );

    actors.addcallback(() {
        txtPoints["points"] = format("%06d", player.points);
    });

    //-------------------------------------------------------------------------

    actors.addcallback(() {
        static int ticks = 0;
        if(SDL_GetTicks() - ticks < 1000) return;
        writeln(game.Profile.info());
        ticks = SDL_GetTicks();
    });

    //*************************************************************************
    //
    // Game loop(s)
    //
    //*************************************************************************

    void drawscreen()
    {
        background.draw();
        doors.draw();
        maze.draw();
        foods.draw();
        mobs.draw();

        hud.draw();
    }

    //-------------------------------------------------------------------------
    // Wait user to press key: simple.gameloop breaks the loop, if event
    // processing function returns false. We create anonymous function to
    // process incoming events.
    //-------------------------------------------------------------------------

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

    doormat.color = vec4(0, 0, 0, 1);
    actors.add(player);

    //-------------------------------------------------------------------------
    // Game loop
    //-------------------------------------------------------------------------

    simple.gameloop(&drawscreen, actors);
}

