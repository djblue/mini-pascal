all: pascal.js

pascal.js: pascal.y; jison pascal.y

# quickly make sure that the parser still works
# might take a few seconds
testparser:; jison pascal.y; ls tests/*.p | xargs -I{} node pascal.js ./{}

clean:; rm -f pascal.js

