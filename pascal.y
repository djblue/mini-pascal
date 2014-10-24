%{
  var inspect = require('util').inspect
    , _ = require('underscore');
    , blocks = []
    , count = 0;
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
    console.log(JSON.stringify(blocks, null, 2));
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
  }
| statement_sequence SEMICOLON statement {
    var last = $1[$1.length - 1];
    // merge two adjacent assignment statements
    if (last.type == 'assign' && $3.type == 'assign') {
      last.end = $3.end;
      last.block = last.block.concat($3.block);
    }
    else if (typeof $3 != 'string') {
      $1.push($3);
    }
  }
;

statement:
  assignment_statement {
    $1.type = 'assign';
    blocks.push($1);
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
  WHILE boolean_expression DO statement {
    $2.type = 'while';
    blocks.push($2);
    if ($4.type == 'compound') {
      $4.forEach(function (t) {
        blocks.push(t)
      })
    } else {
      blocks.push($4)
    }
  }
;

if_statement:
  IF boolean_expression THEN statement ELSE statement {
    $2.type = 'if';
    blocks.push($2)
    if ($4.type == 'compound') {
      $4.forEach(function (t) {
        blocks.push(t)
      })
    } else {
      blocks.push($4)
    }
    if ($6.type == 'compound') {
      $6.forEach(function (t) {
        blocks.push(t)
      })
    } else {
      blocks.push($6)
    }
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
      block: _.flatten($1.block.concat($3.block).concat(merge))
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
