-- ----------------------------------------------------------------------------
-- Testing...
-- ----------------------------------------------------------------------------

print "Hey!"

format = string.format

function loadmessage()
    message = blob.loadtext("data/message.txt");
    return message
end

function howdy()
    print("Version:", _VERSION)
end

function show(num)
    print(format("Hello from %f", num))
    return num
end

-- result = test.heya()
-- write(format("Result: %d\n", result))

