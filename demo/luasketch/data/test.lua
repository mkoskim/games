-- ----------------------------------------------------------------------------
-- Testing...
-- ----------------------------------------------------------------------------

print "Hey!"

-- ----------------------------------------------------------------------------

mytable = {
    a = 1,
    b = 2,
    c = {
        [1] = "a",
        [2] = "c"
    }
}

print(mytable.a, _G.mytable.c[1])

-- ----------------------------------------------------------------------------

format = string.format

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

function passthrough(...)
    gimme(...);
    return 0
    end


-- result = test.heya()
-- write(format("Result: %d\n", result))

return "All done!"

