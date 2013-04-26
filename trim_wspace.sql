-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` FUNCTION `trim_wspace`(txt TEXT CHARSET utf8) RETURNS text CHARSET utf8
    NO SQL
    DETERMINISTIC
    SQL SECURITY INVOKER
    COMMENT 'Trim whitespace characters on both sides'
begin
  declare len INT UNSIGNED DEFAULT 0;
  declare done TINYINT UNSIGNED DEFAULT 0;
  if txt IS NULL then
    return txt;
  end if;
  while not done do
    set len := CHAR_LENGTH(txt);
    set txt = trim(' ' FROM txt);
    set txt = trim('\r' FROM txt);
    set txt = trim('\n' FROM txt);
    set txt = trim('\t' FROM txt);
    set txt = trim('\b' FROM txt);
    if CHAR_LENGTH(txt) = len then
      set done := 1;
    end if;
  end while;
  return txt;
end