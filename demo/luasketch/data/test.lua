-- ----------------------------------------------------------------------------
-- Testing...
-- ----------------------------------------------------------------------------

function loadmessage()
    message = blob.loadtext("data/message.txt");
    return message, 1, "Yes";
end

io.write(string.format("Hello from %s\n", _VERSION))

