program testFunctionLocalVariableNotDeclaredOtherFunction;


class testFunctionLocalVariableNotDeclaredOtherFunction

BEGIN
   VAR otherVar	: integer;
      

FUNCTION testFunctionLocalVariableNotDeclaredOtherFunction1(value : integer): integer;
VAR
   someVar : integer;
BEGIN
   someVar := 6;
   testFunctionLocalVariableNotDeclaredOtherFunction1 := 2
END;

FUNCTION testFunctionLocalVariableNotDeclaredOtherFunction;
BEGIN
   someVar := 5
END

END
.
