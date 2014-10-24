PROGRAM testIfThenElse;

CLASS testIfThenElse

BEGIN
   VAR aa, bb: integer;

FUNCTION testIfThenElse;
BEGIN
  WHILE vv < zz DO
    BEGIN  
      aa := bb;
      bb := aa
    END;
  IF xx + 1 > yy - 3 THEN
    BEGIN
      cc := -1;
      dd := aa + bb * cc - cd;
      ee := 1;
      IF aa <> bb THEN
        aa := bb
      ELSE
        bb := dd
      ;
      cc := da - (bq + cv) * dc
    END
  ELSE
    BEGIN
      ac := da - bq + cv * dc
    END

END

END
.

