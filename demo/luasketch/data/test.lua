-- ----------------------------------------------------------------------------
-- Testing...
-- ----------------------------------------------------------------------------

function loadmessage()
    message = blob.loadtext("data/message.txt");
    return message, 1, "Yes";
end

