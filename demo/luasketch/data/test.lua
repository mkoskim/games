-- ----------------------------------------------------------------------------
-- Testing...
-- ----------------------------------------------------------------------------

function loadmessage()
    message = blob.loadtext("data/message.txt");
    return message
end

function howdy()
    io.write(string.format("Hello from %s\n", _VERSION))
end

function show(num)
    io.write(string.format("Hello from %f\n", num))
    return num
end

