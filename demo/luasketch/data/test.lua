-- ----------------------------------------------------------------------------
-- Testing...
-- ----------------------------------------------------------------------------

-- local info = debug.getinfo(1,'S');
-- print("Loading:", info.source);

-- print(string.format("Testi: %s", "OK"));

-- ----------------------------------------------------------------------------

mytable = {
    a = 1,
    b = 2,
    c = {
        [1] = "a",
        [2] = "c"
    },

    [1]   = "number",
    ["1"] = "string",
}

-- ----------------------------------------------------------------------------

function loadmessage()
    message = blob.loadtext("data/message.txt");
    return message
end

function multiret() return 1, 2, 3, 4 end
function howdy()
    return { 
        a = 1,
        ["1"] = 2,
        [1] = 3,
    }
end

function show(a, b, c)
    print(a, b, c)
    return a
end

function callbounce(...)
    return bounce.bounceback(...);
    end


-- result = test.heya()
-- write(format("Result: %d\n", result))

return string.format("Loaded: %s", debug.getinfo(1,'S').source);
