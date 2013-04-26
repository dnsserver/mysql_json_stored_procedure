-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` FUNCTION `unquote`(txt TEXT CHARSET utf8) RETURNS text CHARSET utf8
    NO SQL
    DETERMINISTIC
    SQL SECURITY INVOKER
    COMMENT 'Unquotes a given text'
begin
  declare quoting_char VARCHAR(1) CHARSET utf8;
  declare terminating_quote_escape_char VARCHAR(1) CHARSET utf8;
  declare current_pos INT UNSIGNED;
  declare end_quote_pos INT UNSIGNED;

  if CHAR_LENGTH(txt) < 2 then
    return txt;
  end if;
  
  set quoting_char := LEFT(txt, 1);
  if not quoting_char in ('''', '"', '`', '/') then
    return txt;
  end if;
  if txt in ('''''', '""', '``', '//') then
    return '';
  end if;
  
  set current_pos := 1;
  terminating_quote_loop: while current_pos > 0 do
    set current_pos := LOCATE(quoting_char, txt, current_pos + 1);
    if current_pos = 0 then
      
      return txt;
    end if;
    if SUBSTRING(txt, current_pos, 2) = REPEAT(quoting_char, 2) then
      set current_pos := current_pos + 1;
      iterate terminating_quote_loop;
    end if;
    set terminating_quote_escape_char := SUBSTRING(txt, current_pos - 1, 1);
    if (terminating_quote_escape_char = quoting_char) or (terminating_quote_escape_char = '\\') then
      
      
      iterate terminating_quote_loop;
    end if;
    
    leave terminating_quote_loop;
  end while;
  if current_pos = CHAR_LENGTH(txt) then
      return SUBSTRING(txt, 2, CHAR_LENGTH(txt) - 2);
    end if;
  return txt;
end