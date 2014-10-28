PROGRAM testIfThenElse;

CLASS testIfThenElse

BEGIN
   VAR aa, bb: integer;

FUNCTION testIfThenElse;
BEGIN
  IF aa > bb THEN
    BEGIN
      IF cc > dd THEN
        BEGIN
          bb := aa + 1
        END
      ELSE
        BEGIN
          cc := aa + 2
        END
    END
  ELSE
    BEGIN
      IF ee > ff THEN
        BEGIN
          bb := aa + 1
        END
      ELSE
        BEGIN
          cc := aa + 2
        END
    END
END

END
.

