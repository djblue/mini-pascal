program testDataTypeDefinedMulti;

class myCustomClass
BEGIN
   VAR
      test : integer;
FUNCTION myCustomClass;
BEGIN
   test := 1
END   
END

class myCustomClass2
BEGIN
   VAR
      test : integer;
FUNCTION myCustomClass2;
BEGIN
   test := 1
END   
END

class testDataTypeDefinedMulti
BEGIN
   VAR 
      lightSwitch	      : myCustomClass;
      lightSwitch2	      : myCustomClass2;
      compilerWorks	      : integer;

FUNCTION TestDataTypeDefinedMulti;
BEGIN
   compilerWorks := 1
END

END
.

