%{
  var _ = require('underscore')
    , blocks = []
    , id = 0
    , enter = null, exit = null
    , lastDummy = null
    , IDENTIFIER = /[a-zA-Z][a-zA-Z0-9]+/
    , count = 0;

    // go through every block and print out
    // all uniq left hand side values
    var printVars = function() {
      var combined = _.chain(blocks)
        .pluck('block')
        .flatten()
        .compact()
        .map(function(block) {
          return block.match(IDENTIFIER);
        })
        .flatten()
        .uniq()
        .sort()
        .value()

      console.log('Vars (output 1)');
      combined.forEach(function(varName) {
        console.log(varName);
      });
      console.log();
    };

    var addBlock = function (block) {
      if (block.id != null) {
        return block;
      }

      block.in = [];

      // make sure start is set
      if (!block.start) {
        block.start = block.end;
      }

      // add id for graph
      block.id = id++;
      // add block to list
      blocks.push(block);

      return block;
    }

    // helper method for adding dummies as blocks
    // note: sets the 'lastDummy' for connect consecutive
    // dummies
    var addDummy = function () {
      var dummy = addBlock({ dummy: true, count: 0, out: [] });

      // this is for connecting consecutive dummy nodes
      if (lastDummy && !lastDummy.out.length) {
        lastDummy.out = [dummy.id];
        dummy.count++;
      }

      lastDummy = dummy;

      return dummy;
    };

    // check if exit has a dummy node,
    // if it does, traverse the dummies
    var traverseDummy = function() {
      var exitNode = blocks[exit];
      if (!exitNode.out) {
        return;
      }

      var complex = isComplex(exitNode);
      var dummy = blocks[exitNode.out[complex]];

      while (dummy.out.length) {
        complex = isComplex(dummy);
        dummy = blocks[dummy.out[complex]];
      }

      exit = dummy.id;
    };

    var isComplex = function(block) {
      return (block.type == 'if' || block.type == 'while') ? 1 : 0;
    }

    var printInfo = function () {
      console.log(JSON.stringify(blocks, null, 2));
      printVars();
      console.log('enter block id: ' + enter);
      console.log('exit block id: ' + exit);
    };

    // TODO: Fix this so that dummy nodes arent
    // created twice.
    var printGraph = function () {
      console.log('digraph cfg {');
      console.log('node [style=filled, shape=box]');
      var start = blocks.filter(function (b) {
        return b.id ==  enter;
      })[0];
      console.log('start -> "' + start.id + '\n' + start.block.join('\n') + '"');

      blocks.forEach(function (b) {
        if (b.block) {
          var node = '"' + b.id + '\n' + b.block.join('\n') + '"';
        } else {
          var node = '"' + b.id + '\ndummy"';
        }
        /* console.log(node); */
        if (b.out) {
          b.out.forEach(function (o) {
            var to = blocks.filter(function (b) {
              return b.id ==  o;
            })[0]
            if (to.block) {
              console.log(node + '->' + '"' + to.id + '\n' + to.block.join('\n') + '"' + ";");
            } else {
              console.log(node + '->' + ' "' + to.id + '\ndummy"');
            }
          })
        }
      })

      var end = blocks.filter(function (b) {
        return b.id == exit;
      })[0];
      if (end.block) {
        console.log('end -> "' + end.id + '\n' + end.block.join('\n') + '"');
      } else {
        console.log('end ->' + ' "' + end.id + '\ndummy"');
      }

      console.log('}');
    }

    var forwardDummy = function (dummies, block) {
      if (block.out) {
        var forward = false;
        var out = block.out.map(function (o) {
          if (dummies[o] && dummies[o].out > 0) {
            dummies[o].count--;
            forward = true;
            return dummies[o].out;
          } else {
            return [o];
          }
        })
        var flat = [].concat.apply([], out);
        block.out = flat;
        if (forward) {
          forwardDummies(dummies, block);
        }
      }
    };

    var forwardDummies = function () {
      var dummies = blocks.reduce(function (map, b) {
        if (b.dummy) {
          map[b.id] = b;
        }
        return map;
      }, {});
      blocks.forEach(function (block) {
        forwardDummy(dummies, block)
      });
      blocks = blocks.filter(function (block) {
        if (block.count < 1) {
          return false
        } else {
          return true;
        }
      })
    };

    var addIn = function () {
      blocks.forEach(function(block) {

        block.out && block.out.forEach(function(out) {
          var to = _.findWhere(blocks, { id: out });
          to.in.push(block.id);
        });

      });
    };

    var processBlock = function (b) {

        // value numbers
        var v = {};

        // hash values
        var h = {};
        var hashes = 0;
        var index = 0;
        var block = b.block;

        var newHash = function(id) {
          var hash = '#' + ++hashes;
          v[id] = {
            hash: hash
          };

          h[hash] = {
            expr: hash,
            hash: hash
          };

          // if number, dont add to table
          // just return it
          if (!isNaN(+id)) {
            v[id].const = true;
            v[id].value = Number(id);
          }

          return v[id];
        };

        var lookup = function(id) {
          if (id == undefined) {
            return {};
          }

          return v[id] || newHash(id);
        };

        // finds the expression in the h table
        var findExpr = function(op, v1, v2) {
          var h1 = v1.hash;
          var h2 = v2.hash;
          var expr;
          if (op == '+' || op == '*') {
            var v1 = h1 && Number(h1.slice(1));
            var v2 = h2 && Number(h2.slice(1));
            expr = (v2 > v1) ? [op, h2, h1] : [op, h1, h2];
          }
          else {
            expr = [op, h1, h2];
          }

          expr = expr.join('');
          var exists = _.chain(h)
            .values()
            .find(function (row) {
              return row.expr == expr || row.hash == expr;
            })
            .value()

          if (exists) {
            return exists.hash;
          }

          var hash = '#' + ++hashes;
          h[hash] = {
            expr: expr,
            hash: hash
          };

          return hash;
        };

        // a = b + c ---> <a> = <b> <op> <c>
        var parseExpr = function(expr) {
          var expr = expr.split(' ');
          return {
            a: expr[0],
            b: expr[2],
            op: expr[3],
            c: expr[4]
          }
        };

        console.log('block ' + JSON.stringify(block, null, 2));
        var temp = [];
        block.forEach(function(expr) {
          // console.log('expr ' + expr);

          var expr = parseExpr(expr);
          var v1 = lookup(expr.b);
          var v2 = lookup(expr.c);
          var hash = findExpr(expr.op, v1, v2);

          // aa = 1 + 2
          // aa = bb + 1 where aa is a constant
          // aa = 1 + cc where cc is a constant
          // aa = dd + ee where dd and cc is a constant
          if (v1.const && v2.const) {
            v[expr.a] = {
              const: true,
              value: eval(v1.value + expr.op + v2.value)
            };
          }

          // aa = 1
          // aa = bb // where bb is a const
          else if (v1.const && _.isEmpty(v2)) {
            v[expr.a] = {
              const: true,
              value: v1.value
            };
          }

          // aa = 1 + bb where bb is not a constant
          // aa = cc + bb where  bb == not a constant and cc == constant
          //else if (v1.const) {

          //}

          // aa = bb + 1 where bb is not a constant
          // aa = bb + cc where  bb == not a constant and cc == constant
          //else if (v2.const) {

          //}

          // aa = cc where cc is not a constant
          // aa = aa + bb where aa and bb are not constants
          else {
            // console.log('v1 ' + v1.hash);
            // console.log('v2 ' + v2.hash);

            v[expr.a] = {
              hash: hash
            };
          }

          //temp.push(expr.a + ' = ' + );
          //console.log('temp ' + temp);


          // console.log('expr.b ' + expr.b);
          // console.log('h1 ' + JSON.stringify(h1, null, 2));
          // console.log('expr.c ' + expr.c);
          // console.log('h2 ' + JSON.stringify(h2, null, 2));


          index++;
        });

        console.log('v ' + JSON.stringify(v, null, 2));
        console.log('h ' + JSON.stringify(h, null, 2));


        // print out vars with values
    };

    var valueNumbering = function() {
      blocks.forEach(processBlock);
    };
%}

%lex

%options flex case-insensitive

%%

\s+         {}

"PROGRAM"   { return 'PROGRAM'; }
"AND"       { return 'AND'; }
"ARRAY"     { return 'ARRAY'; }
"CLASS"     { return 'CLASS'; }
"DO"        { return 'DO'; }
"ELSE"      { return 'ELSE'; }
"END"       { return 'END'; }
"EXTENDS"   { return 'EXTENDS'; }
"FUNCTION"  { return 'FUNCTION'; }
"IF"        { return 'IF'; }
"MOD"       { return 'MOD'; }
"NEW"       { return 'NEW'; }
"NOT"       { return 'NOT'; }
"OF"        { return 'OF'; }
"OR"        { return 'OR'; }
"PRINT"     { return 'PRINT'; }
"BEGIN"     { return 'BEGIN'; }
"THEN"      { return 'THEN'; }
"VAR"       { return 'VAR'; }
"WHILE"     { return 'WHILE'; }

[a-zA-Z]([a-zA-Z0-9])+    { return 'IDENTIFIER'; }

":="        { return 'ASSIGNMENT'; }
":"         { return 'COLON'; }
","         { return 'COMMA'; }
[0-9]+      { return 'DIGSEQ'; }
"."         { return 'DOT';} }
".."        { return 'DOTDOT'; }
"="         { return 'EQUAL'; }
">="        { return 'GE'; }
">"         { return 'GT'; }
"["         { return 'LBRAC'; }
"<="        { return 'LE'; }
"("         { return 'LPAREN'; }
"<"         { return 'LT'; }
"-"         { return 'MINUS'; }
"<>"        { return 'NOTEQUAL'; }
"+"         { return 'PLUS'; }
"]"         { return 'RBRAC'; }
")"         { return 'RPAREN'; }
";"         { return 'SEMICOLON'; }
"/"         { return 'SLASH'; }
"*"         { return 'STAR'; }

/lex

%end program

%% /* language grammar */

program:
  program_heading SEMICOLON class_list DOT {
    traverseDummy();
    addIn();
    valueNumbering();

    // this removes nodes so it needs to be last
    // TODO: Fix a weird bug where this is either removing
    // nodes and not updating out arrays or incorrectly
    // remove nodes. see tests/if_if.p
    forwardDummies();

    if (process.argv[3] == '--graph') {
      printGraph();
    } else {
      // printInfo();
    }
  }
;

program_heading:
  PROGRAM identifier {
  }
| PROGRAM identifier LPAREN identifier_list RPAREN {
  }
;

identifier_list:
  identifier_list COMMA identifier {
  }
| identifier {
  }
;

class_list:
  class_list class_identification BEGIN class_block END {
  }
| class_identification BEGIN class_block END {
  }
;

class_identification:
  CLASS identifier {
  }
| CLASS identifier EXTENDS identifier {
  }
;

class_block:
  variable_declaration_part func_declaration_list {
  }
;

type_denoter:
  array_type {
  }
| identifier {
  }
;

array_type:
  ARRAY LBRAC range RBRAC OF type_denoter {
  }
;

range:
  unsigned_integer DOTDOT unsigned_integer {
  }
;

variable_declaration_part:
  VAR variable_declaration_list SEMICOLON {
  }
|
  {
  }
;

variable_declaration_list:
  variable_declaration_list SEMICOLON variable_declaration {
  }
| variable_declaration {
  }
;

variable_declaration:
  identifier_list COLON type_denoter {
  }
;

func_declaration_list:
  func_declaration_list SEMICOLON function_declaration {
  }
| function_declaration {
  }
| {
  }
;

formal_parameter_list:
  LPAREN formal_parameter_section_list RPAREN {
  }
;

formal_parameter_section_list:
  formal_parameter_section_list SEMICOLON formal_parameter_section {
  }
| formal_parameter_section {
  }
;

formal_parameter_section:
  value_parameter_specification {
  }
| variable_parameter_specification {
  }
;

value_parameter_specification:
  identifier_list COLON identifier {
  }
;

variable_parameter_specification:
  VAR identifier_list COLON identifier {
  }
;

function_declaration:
  function_identification SEMICOLON function_block {
  }
| function_heading SEMICOLON function_block {
  }
;

function_heading:
  FUNCTION identifier COLON result_type {
  }
| FUNCTION identifier formal_parameter_list COLON result_type {
  }
;

result_type:
  identifier {
  }
;

function_identification:
  FUNCTION identifier {
  }
;

function_block:
  variable_declaration_part statement_part {
    //console.log(JSON.stringify($2, null, 2));
    enter = $2[0].id;
    exit = $2[$2.length - 1].id;
  }
;

statement_part:
  compound_statement {
  }
;

compound_statement:
  BEGIN statement_sequence END {
    $$ = $2;
  }
;

statement_sequence:
  statement {
    $$ = [$1];
    addBlock($1);
    // console.log('$1 ' + JSON.stringify($1, null, 2));
  }
| statement_sequence SEMICOLON statement {
    var last = $1[$1.length - 1];
    // console.log('last ' + JSON.stringify(last, null, 2));
    // console.log('$3 ' + JSON.stringify($3, null, 2));

    // merge two adjacent assignment statements
    if (last.type == 'assign' && $3.type == 'assign') {
      last.end = $3.end;
      last.block = last.block.concat($3.block);
    }

    // these can be joined into one block, so just do that
    else if (last.type == 'assign' && $3.type == 'if') {
      last = _.extend(last, {
        end: $3.end,
        block: last.block.concat($3.block),
        type: $3.type,
        out: $3.out
      });
    }

    // these cant be joined, instead forward the dummy
    // node to assignment
    else if (last.type == 'if' && $3.type == 'assign') {
      var left = _.findWhere(blocks, { id: last.out[0] });
      var dummy = _.findWhere(blocks, {  id: left.out [0] });

      // the branch could be another complex statement :S
      if (left.type == 'if' || left.type == 'while')
        lastDummy.out = [addBlock($3).id];
      else
        dummy.out = [addBlock($3).id];

      // point the dummy node the next statement
      $1.push($3);
    }

    // these cant be joined, instead point the assign
    // statement to the while condition
    else if (last.type == 'assign' && $3.type == 'while') {
      last.out = [];
      last.out.push(addBlock($3).id);
      $1.push($3);
    }

    // these cant be joined, instead point the while
    // dummy node to the assign statement
    else if (last.type == 'while' && $3.type == 'assign') {
      var dummy = _.findWhere(blocks, {  id: last.out[1] });

      // point the dummy node the next statement
      dummy.out = [addBlock($3).id];
      $1.push($3);
    }


    // these cant be joined, instead point the while
    // dummy node to the if condition block
    else if (last.type == 'while' && $3.type == 'if') {
      var dummy = _.findWhere(blocks, {  id: last.out[1] });

      // point the dummy to the start of the if condition
      dummy.out = [addBlock($3).id];
      $1.push($3);
    }

    // these cant be joined, instead point the if dummy
    // to the while dummy
    else if (last.type == 'if' && $3.type == 'while') {
      var left = _.findWhere(blocks, { id: last.out[0] });
      var dummy = _.findWhere(blocks, {  id: left.out[0] });

      // point the dummy node the next statement
      dummy.out = [addBlock($3).id];
      $1.push($3);
    }
  }
;

statement:
  assignment_statement {
    $1.type = 'assign';
  }
| compound_statement {
    $1.type = 'compound';
  }
| if_statement {
  }
| while_statement {
  }
| print_statement {
  }
;

while_statement:
  // TODO: Refactor how this is parsed if we have time. I'm pretty sure
  // this can be done in a muuuuch easier way.
  WHILE boolean_expression DO statement {
    $2.type = 'while';
    $2.out = [];

    addBlock($2);
    if ($4.type == 'compound') {
      $4.forEach(function (t) {
        addBlock(t);
      });

      // connect the condition to the body
      $2.out.push($4[0].id);

      if (!$4[$4.length - 1].out) {
        $4[$4.length - 1].out = [];
      }

      // connect the body back to the condition
      var last = $4[$4.length - 1];
      last.out.push($2.id);
    }
    else {
      // connect the condition to the body
      $2.out.push($4.id);

      if (!$4.out) {
        $4.out = [];
      }

      // connect the body back to the condition
      $4.out.push($2.id);
      addBlock($4);
    }

    // add dummy false condition
    var dummy = addDummy();
    $2.out.push(dummy.id);
    dummy.count++;

    $$ = $2;
  }
;

if_statement:
  // TODO: Refactor how this is parsed if we have time. I'm pretty sure
  // this can be done in a muuuuch easier way.
  IF boolean_expression THEN statement ELSE statement {
    $2.type = 'if';
    $2.out = [];

    var dummy = addDummy();
    if ($4.type == 'compound') {

      // point the condition to the true branch
      $2.out.push($4[0].id);

      // append dummy node to last of true
      var last = $4[$4.length - 1];

      // I don't like this, but it works. If you have
      // an if and another if the following assignemnt
      // won't work
      if (!last.out) {
        last.out = [dummy.id];
        dummy.count++;
      }
    }
    else {
      addBlock($4);

      // point the condition to the true branch
      $2.out.push($4.id);

      // point the true condition the dummy
      $4.out = [dummy.id];
      dummy.count++;
    }

    // same rules as true branch
    if ($6.type == 'compound') {
      $2.out.push($6[0].id);

      // append dummy
      var last = $6[$6.length - 1];
      if (!last.out) {
        last.out = [dummy.id];
        dummy.count++;
      }
    }
    else {
      addBlock($6);

      $2.out.push($6.id);
      $6.out = [dummy.id];
      dummy.count++;
    }

    $$ = $2;
    /* console.log(JSON.stringify($2, null, 2)); */
  }
;

assignment_statement:
  variable_access ASSIGNMENT expression {
    $3.block.push($1 + ' = ' + $3.end);
    $3.end = $1;
    $$ = $3;
    //console.log(JSON.stringify($$, null, 2));
  }
| variable_access ASSIGNMENT object_instantiation {
  }
;

object_instantiation:
  NEW identifier {
  }
| NEW identifier params {
  }
;

print_statement:
  PRINT variable_access {
  }
;

variable_access:
  identifier {
  }
| indexed_variable {
  }
| attribute_designator {
  }
| method_designator {
  }
;

indexed_variable:
  variable_access LBRAC index_expression_list RBRAC {
  }
;

index_expression_list:
  index_expression_list COMMA index_expression {
  }
| index_expression {
  }
;

index_expression:
  expression {
  }
;

attribute_designator:
  variable_access DOT identifier {
  }
;

method_designator:
  variable_access DOT function_designator {
  }
;

params:
  LPAREN actual_parameter_list RPAREN {
  }
;

actual_parameter_list:
  actual_parameter_list COMMA actual_parameter{
  }
| actual_parameter {
  }
;

actual_parameter:
  expression {
  }
| expression COLON expression {
  }
| expression COLON expression COLON expression {
  }
;

boolean_expression:
  expression {
  }
;

expression:
  simple_expression {
  }
| simple_expression relop simple_expression {
    var t = 't'+ count++;
    var merge = t + ' = ' + $1.end + ' ' + $2 + ' ' +  $3.end;
    $$ = {
      start: $1.start || $3.start || t,
      end: t,
      block: $1.block.concat($3.block).concat(merge)
    };
    //console.log('e: ' + JSON.stringify($$, null, 2));
  }
;

simple_expression:
  term {
  }
| simple_expression addop term {
    var t = 't'+ count++;
    var merge = t + ' = ' + $1.end + ' ' + $2 + ' ' + $3.end;
    $$ = {
      start: $1.start || $3.start || t,
      end: t,
      block: $1.block.concat($3.block).concat(merge)
    };
    //console.log('se: ' + JSON.stringify($$, null, 2));
  }
;

term:
  factor {
    // check if factory was a primary of just a factor
    if (typeof $1 == 'string') {
      $$ = {
        end: $1,
        block: []
      };
    }
  }
| term mulop factor {
    var t = 't'+ count++;
    var merge = t + ' = ' + $1.end + ' ' + $2 + ' ' + ($3.end || $3);
    $$ = {
      start: $1.start || $3.start || t,
      end: t,
      block: _.compact($1.block.concat($3.block).concat(merge))
    };
    /* console.log('term: ' + JSON.stringify($$, null, 2)); */
  }
;

sign:
  PLUS {
  }
| MINUS {
  }
;

factor:
  sign factor {
    var t = 't'+ count++;
    if (typeof $2 == 'string') {
      $$ = {
        start: t,
        end: t,
        block: [t + ' = ' + 0 + ' - ' + $2]
      };
    } else {
      $$ = {
        start: $2.start || t,
        end: t,
        block: $2.block.concat([t + ' = ' + 0 + ' - ' + $2.end])
      };
    }
  }
| primary {
  }
;

primary:
  variable_access {
  }
| unsigned_constant {
  }
| function_designator {
  }
| LPAREN expression RPAREN {
    $$ = $2;
  }
| NOT primary {
  }
;

unsigned_constant:
  unsigned_number {
  }
;

unsigned_number:
  unsigned_integer {
  }
;

unsigned_integer:
  DIGSEQ {
  }
;

function_designator:
  identifier params {
  }
;

addop:
  PLUS {
  }
| MINUS {
  }
| OR {
  }
;

mulop:
  STAR {
  }
| SLASH {
  }
| MOD {
  }
| AND {
  }
;

relop:
  EQUAL {
  }
| NOTEQUAL {
  }
| LT {
  }
| GT {
  }
| LE {
  }
| GE {
  }
;

identifier:
  IDENTIFIER {
  }
;
