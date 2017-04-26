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
    return 1, 2, 3
end

function show(a, b, c)
    print(format("show(%f, %f, %f)", a, b, c))
    return a
end

-- result = test.heya()
-- write(format("Result: %d\n", result))

