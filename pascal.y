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

%start program

%% /* language grammar */

program:
  program_heading SEMICOLON class_list DOT {
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
  }
;

statement_part:
  compound_statement {
  }
;

compound_statement:
  BEGIN statement_sequence END {
    console.log(JSON.stringify($2, null, 2));
  }
;

statement_sequence:
  statement {
    $$ = [$1];
  }
| statement_sequence SEMICOLON statement {
    $1.push($3);
    $$ = $1;
  }
;

statement:
  assignment_statement {
    $$ = $1;
  }
| compound_statement {
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
  }
;

if_statement:
  IF boolean_expression THEN statement ELSE statement {
  }
;

assignment_statement:
  variable_access ASSIGNMENT expression {
    $$ = {};
    $$[$1] = $3;
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
    $$ = $1;
  }
| simple_expression relop simple_expression {
  }
;

simple_expression:
  term {
    $$ = $1;
  }
| simple_expression addop term {
    $$ = {
      left: $1,
      op: $2,
      right: $3
    };
  }
;

term:
  factor {
  }
| term mulop factor {
    $$ = {
      left: $1,
      op: $2,
      right: $3
    };
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
