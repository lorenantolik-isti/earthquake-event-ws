delimiter //
DROP FUNCTION IF EXISTS point_in_one_polygon//
CREATE FUNCTION point_in_one_polygon(p POINT, poly POLYGON) RETURNS INT(1)
COMMENT 'Should be combined with MBRContains as a prefilter'
-- This function is based on myWithin which can be found at:
--     http://forums.mysql.com/read.php?23,366732,366732
-- It has been modified so if point is on a vertex or edge it returns 1
-- immediately.
DETERMINISTIC
BEGIN
  DECLARE n INT DEFAULT 0;
  DECLARE pX DECIMAL(9,6);
  DECLARE pY DECIMAL(9,6);
  DECLARE ls LINESTRING;
  DECLARE poly1 POINT;
  DECLARE poly1X DECIMAL(9,6);
  DECLARE poly1Y DECIMAL(9,6);
  DECLARE poly2 POINT;
  DECLARE poly2X DECIMAL(9,6);
  DECLARE poly2Y DECIMAL(9,6);
  DECLARE i INT DEFAULT 0;
  DECLARE result INT(1) DEFAULT 0;
  DECLARE y_intercept DECIMAL(9,6);

  SET pX = ST_X(p);
  SET pY = ST_Y(p);
  SET ls = ST_ExteriorRing(poly);
  SET poly2 = ST_EndPoint(ls);
  SET poly2X = ST_X(poly2);
  SET poly2Y = ST_Y(poly2);
  SET n = ST_NumPoints(ls);

  -- this is the infinite ray test, drawn straight down instead of to the right
  WHILE i < n DO
    SET poly1 = ST_PointN(ls, (i+1));
    SET poly1X = ST_X(poly1);
    SET poly1Y = ST_Y(poly1);

    IF (pX = poly1X && pY = poly1Y) THEN
      -- on end point, return true
      RETURN 1;
    ELSEIF (( (poly1X <= pX) && (pX < poly2X) ) ||
  ( (poly2X <= pX) && (pX < poly1X) )) THEN
      -- between x values, test y
      SET y_intercept = poly1Y + (poly2Y - poly1Y) * (pX - poly1X) / (poly2X - poly1X);
      IF y_intercept = pY THEN
  -- on segment, return true
  RETURN 1;
      ELSEIF pY > y_intercept THEN
  -- above segment, toggle result
  SET result = !result;
      END IF;
    END IF;

    SET poly2X = poly1X;
    SET poly2Y = poly1Y;
    SET i = i + 1;
  END WHILE;

  RETURN result;
END;
//
delimiter ;
