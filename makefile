all: pascal.js

pascal.js: pascal.y; @./node node_modules/jison/lib/cli.js pascal.y

# quickly make sure that the parser still works
# might take a few seconds
testparser:; pascal.y; ls tests/*.p | xargs -I{} ./node pascal.js ./{}

clean:; rm -f pascal.js
