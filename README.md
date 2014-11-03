# mini-pascal

## Get Going
This repo comes with a node build for both mac and linux systems.

* If you are running on mac use `./node-mac-32` pascal.js <FILE>
* If you are running on linux use `./node` pascal.js <FILE>

This will print out the CFG, followed by the vars and the entry/exit points.
For example, on mac try
```
./node-mac-32 pascal.js tests/if_else_assignment.p
```

Next to print out the CFG/vars with value numbering, use the option `--valnum`
ex.
`./node(or ./node-mac-32) pascal.js <FILE> --valnum`
Again for example, on mac try
./node-mac-32 pascal.js tests/if_else_assignment.p --valnum


## Using a graph
If you would like to create an actual graph of the CFG and you have homebrew installed,
run
```
homebrew install graphviz
./node pascal.js <FILE> --graph | dot -Tpng > graph.png
open graph.png
```

## Options
* --valnum - transforms by performing value numbering on the basic blocks
* --graph` - creates a graph, assuming graphviz is installed (see Using a graph)

## Tests
Various tests are located in the test directory. Feel free to use them.



