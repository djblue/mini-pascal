PROGRAM testIfThenElse;

CLASS testIfThenElse

BEGIN
   VAR aa, bb: integer;

FUNCTION testIfThenElse;
BEGIN
  IF xx + 1 > yy - 3 THEN
    BEGIN
      bb := aa + 1
    END
  ELSE
    BEGIN
      cc := aa + 2
    END
  ;

  aa := 1 + 2
END

END
.

