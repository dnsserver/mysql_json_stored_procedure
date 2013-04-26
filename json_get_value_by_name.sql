-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` FUNCTION `json_get_value_by_name`(
    json_text text charset utf8,
    p_name     text charset utf8
) RETURNS text CHARSET utf8
    MODIFIES SQL DATA
    DETERMINISTIC
    SQL SECURITY INVOKER
    COMMENT 'Get value from json field'
begin
    declare v_from, v_old_from int unsigned;
    declare v_token text;
    declare v_level int;
    declare v_state, expect_state varchar(255);
    declare _json_tokens_id int unsigned default 0;
    declare is_lvalue, is_rvalue tinyint unsigned;
    declare start_object tinyint unsigned;
    declare scope_stack text charset ascii;
    declare l_value text charset utf8;
    declare r_value text charset utf8;
    declare found_name, found_value tinyint unsigned;
    

    set json_text := trim_wspace(json_text);
    
    set expect_state := 'object_begin,array_begin';
    set is_lvalue := true;
    set is_rvalue := false;
    set start_object := false;
    set scope_stack := '';
    set r_value := '';
    set l_value := '';
    set found_name := false;
    set found_value := false;

    get_token_loop: repeat 
        set v_old_from = v_from;
        call _get_json_token(json_text, v_from, v_level, v_token, 1, v_state);
        set _json_tokens_id := _json_tokens_id + 1;
        if v_state = 'whitespace' then
          iterate get_token_loop;
        end if;
        if v_level < 0 then
          return null;
        end if;
        if v_state = 'start' and scope_stack = '' then
          leave get_token_loop;
        end if;
        if FIND_IN_SET(v_state, expect_state) = 0 then
          return null;
        end if;
        if v_state = 'array_end' and left(scope_stack, 1) = 'o' then
          return null;
        end if;
        if v_state = 'object_end' and left(scope_stack, 1) = 'a' then
          return null;
        end if;
        if v_state = 'alpha' and lower(v_token) not in ('true', 'false', 'null') then
          return null;
        end if;
        set is_rvalue := false;
        case 
          when v_state = 'object_begin' then set expect_state := 'string', found_name := false, found_value := false, scope_stack := concat('o', scope_stack), is_lvalue := true;
          when v_state = 'array_begin' then set expect_state := 'string,object_begin', found_name := false,found_value := false, scope_stack := concat('a', scope_stack), is_lvalue := false;
          when v_state = 'string' and is_lvalue then set expect_state := 'colon', l_value := unquote(v_token);
          when v_state = 'colon' then set expect_state := 'string,number,alpha,object_begin,array_begin', is_lvalue := false;
          when FIND_IN_SET(v_state, 'string,number,alpha') and not is_lvalue then set expect_state := 'comma,object_end,array_end', is_rvalue := true;
          when v_state = 'object_end' then set expect_state := 'comma,object_end,array_end', found_name := false, found_value := false,scope_stack := substring(scope_stack, 2);
          when v_state = 'array_end' then set expect_state := 'comma,object_end,array_end', found_name := false, found_value := false, scope_stack := substring(scope_stack, 2);
          when v_state = 'comma' and left(scope_stack, 1) = 'o' then set expect_state := 'string', is_lvalue := true;
          when v_state = 'comma' and left(scope_stack, 1) = 'a' then set expect_state := 'string,object_begin', is_lvalue := false;
        end case;

        if is_rvalue then
          set r_value = unquote(v_token);
          if found_value then
            return r_value;
          elseif r_value = p_name and l_value = 'name' then
            set found_name := true;
          end if;
        end if;
        if is_lvalue and found_name and l_value = 'value' then
            set found_value := true;
        end if;
    until 
        v_old_from = v_from
    end repeat;
    return null;
end