-- ----------------------------------------------------------------------------
-- Testing...
-- ----------------------------------------------------------------------------

print "Hey!"

-- ----------------------------------------------------------------------------

mytable = {
    a = 1,
    b = 2,
}

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
    print(format("show(%f, %f, %f)", a, b, c))
    return a
end

function passthrough(...)
    gimme(...);
    end


-- result = test.heya()
-- write(format("Result: %d\n", result))

return "All done!"

