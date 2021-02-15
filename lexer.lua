local Lexer = {}

function Lexer:new(file)
	self.cursor_start = 1
	self.cursor_end   = 1
	self.tokens       = {}
	self.file         = file
end

function Lexer:tokenize(file)
	self:new(file)

	while not self:eof() do
		self:tokenize_next_element()
	end

	return self.tokens
end

function Lexer:tokenize_next_element()
	if not self:peek() then return end
	
	local peek_1  = self:peek()
	local peek_2  = self:peek(2)
	local peek_3  = self:peek(3)
	local peek_4  = self:peek(4)
	local chain_2 = self:peek_chain(2)
	local chain_3 = self:peek_chain(3)

	-- whitespace
	if self:match_whitespace(peek_1) then 
		return self:tokenize_whitespace()

	-- identifier && keyword
	elseif self:match_identifier_start(peek_1) then 
		return self:tokenize_keyword_or_identifier()

	-- number
	elseif self:match_decimal(peek_1) or (peek_1 == "." and self:match_decimal(peek_2)) then 
		return self:tokenize_number()

	-- simple string
	elseif self:match_quote(peek_1) then 
		return self:tokenize_simple_string()

	-- long string
	elseif chain_2 == "[[" or chain_2 == "[=" then 
		return self:tokenize_long_string()

	-- simple comment 
	elseif (chain_2 == "--" and peek_3 ~= "[") or (chain_3 == "--[" and peek_4 ~= "[" and peek_4 ~= "=") then
		return self:tokenize_short_comment()

	-- long comment && one case of simple comment
	elseif chain_3 == "--[" and (peek_4 == "[" or peek_4 == "=") then 
		return self:tokenize_simple_or_long_comment()

	-- symbol
	elseif chain_3 == "..=" then self:increment(2) return self:split("CONCAT_EQ")
	elseif chain_3 == "..." then self:increment(2) return self:split("ARGS")
	elseif chain_2 == "=="  then self:increment()  return self:split("EQUAL_OP")
	elseif chain_2 == ">="  then self:increment()  return self:split("GREAT_EQ_OP")	
	elseif chain_2 == "<="  then self:increment()  return self:split("LESS_EQ_OP")
	elseif chain_2 == "+="  then self:increment()  return self:split("PLUS_EQ")
	elseif chain_2 == "-="  then self:increment()  return self:split("MINUS_EQ")
	elseif chain_2 == "!="  then self:increment()  return self:split("DIF_EQ!")
	elseif chain_2 == "~="  then self:increment()  return self:split("DIF_EQ~")
	elseif chain_2 == "*="  then self:increment()  return self:split("TIME_EQ")
	elseif chain_2 == "/="  then self:increment()  return self:split("DIV_EQ")
	elseif chain_2 == "%="  then self:increment()  return self:split("MOD_EQ")
	elseif chain_2 == "++"  then self:increment()  return self:split("INCREMENT")
	elseif chain_2 == '..'  then self:increment()  return self:split("CONCAT_STR")
	elseif chain_2 == "&&"  then self:increment()  return self:split("AND&&")
	elseif chain_2 == "||"  then self:increment()  return self:split("OR||")
	elseif chain_2 == ">>"  then self:increment()  return self:split("BITWISE_>>")
	elseif chain_2 == "<<"  then self:increment()  return self:split("BITWISE_<<")
	elseif chain_2 == "::"  then self:increment()  return self:split("GOTO::")
	elseif peek_1  == '['   then                   return self:split("L_BRACKET")
	elseif peek_1  == ']'   then                   return self:split("R_BRACKET")
	elseif peek_1  == '('   then                   return self:split("L_PARENT")
	elseif peek_1  == ')'   then                   return self:split("R_PARENT")
	elseif peek_1  == '{'   then                   return self:split("L_CURLY")
	elseif peek_1  == '}'   then                   return self:split("R_CURLY")
	elseif peek_1  == '>'   then                   return self:split("LESS")
	elseif peek_1  == '<'   then                   return self:split("GREATER")
	elseif peek_1  == '='   then                   return self:split("EQUAL")
	elseif peek_1  == '%'   then                   return self:split("MODULO")
	elseif peek_1  == '@'   then                   return self:split("SELF@")
	elseif peek_1  == '!'   then                   return self:split("NOT!")
	elseif peek_1  == '?'   then                   return self:split("QMARK")
	elseif peek_1  == ':'   then                   return self:split("COLON")
	elseif peek_1  == ';'   then                   return self:split("SEMICOLON")
	elseif peek_1  == ','   then                   return self:split("COMMA")
	elseif peek_1  == '+'   then                   return self:split("PLUS")
	elseif peek_1  == '-'   then                   return self:split("MINUS")
	elseif peek_1  == '*'   then                   return self:split("MULTI")
	elseif peek_1  == '/'   then                   return self:split("DIVIDE")
	elseif peek_1  == '^'   then                   return self:split("POWER")
	elseif peek_1  == '#'   then                   return self:split("HASHTAG")
	elseif peek_1  == '&'   then                   return self:split("AMP")
	elseif peek_1  == '.'   then                   return self:split("DOT")
	elseif peek_1  == '\n'  then                   return self:split("NL_N")
	elseif peek_1  == '\r'  then                   return self:split("NL_R")        

	-- if nothing match, one char is returned
	else
		return self:split("???")
	end
end

function Lexer:tokenize_simple_string()
	local quote = self:peek()

	self:increment()
	while true do
		local chars = self:peek_chain(2)
		if     chars == [[\\]]         then self:increment()
		elseif chars == [[\]] .. quote then self:increment(2) end

		if self:peek() == quote  then return self:split("S_STRING") end
		if self:peek() == "\n"   then error("invalid short string") end
		if not self:increment()  then error("oef short string ")    end
	end
end

function Lexer:tokenize_keyword_or_identifier()
	while self:match_identifier(self:peek(2)) do
		self:increment()
	end

	local token = self:get_current_token()
	-- default lua keywords
	if token == "if"       then return self:split('KW_if')		 end
	if	token == "then"     then return self:split('KW_then')		 end
	if	token == "else"     then return self:split('KW_else')		 end
	if	token == "elseif"   then return self:split('KW_elseif')	 end
	if	token == "end"      then return self:split('KW_end')		 end
	if	token == "do"       then return self:split('KW_do')		 end
	if	token == "for"      then return self:split('KW_for')		 end
	if	token == "function" then return self:split('KW_function') end
	if	token == "repeat"   then return self:split('KW_repeat')	 end
	if	token == "until"    then return self:split('KW_until')	 end
	if	token == "while"    then return self:split('KW_while')	 end
	if	token == "break"    then return self:split('KW_break')	 end
	if	token == "return"   then return self:split('KW_return')	 end
	if	token == "local"    then return self:split('KW_local')	 end
	if	token == "in"       then return self:split('KW_in')		 end
	if	token == "not"      then return self:split('KW_not')		 end
	if	token == "and"      then return self:split('KW_and')		 end
	if	token == "or"       then return self:split('KW_or')		 end
	if	token == "goto"     then return self:split('KW_goto')		 end
	if	token == "self"     then return self:split('KW_self')		 end
	if	token == "true"     then return self:split('KW_true')		 end
	if	token == "false"    then return self:split('KW_false')	 end
	if	token == "nil"      then return self:split('KW_nil')		 end

	-- custom keywords
	if	token == "fn"       then return self:split('KW_fn')		 end
	if	token == "ifor"     then return self:split('KW_ifor')		 end
	if	token == "rfor"     then return self:split('KW_rfor')		 end
	if	token == "elif"     then return self:split('KW_elif')		 end
	if	token == "switch"   then return self:split('KW_switch')	 end
	if	token == "case"     then return self:split('KW_case')		 end
	
	return self:split('IDENTIFIER')
end

function Lexer:tokenize_long_string()
	local counter = 0

	self:increment()
	if self:peek() == "=" then
		while true  do
			if self:peek() == "=" then 
				counter = counter + 1 
				if not self:increment() then error("invalid long string") end
			elseif self:peek() == "[" then 
				break
			else 
				error( "invalid long string") 
			end
		end
	end

	if self:peek() == "[" then
		while true do
			if self:eof() then error("invalid long string") end

			self:increment()
			if self:peek() == "]" then
				for i = 1, counter do
					self:increment()
					if  self:peek() ~= "=" then goto continue_longstring_increment end
				end

				self:increment()
				if self:peek() == "]" then return self:split("LONG_STRING") end
				::continue_longstring_increment::
			end
		end
	end
end

function Lexer:tokenize_simple_or_long_comment()
	self:increment(3)
	
	local counter = 0
	if self:peek() == "=" then
		while true  do
			if self:peek() == "=" then
				counter = counter + 1
				self:increment()
			elseif self:peek() == "[" then 
				break
			else   
				return self:tokenize_short_comment()
			end
		end
	end

	while true do
		if self:eof() then error("invalid long comment") end

		self:increment()
		if self:peek() == "]" then
			for i = 1, counter do
				self:increment()
				if  self:peek() ~= "=" then 
					goto continue_long_comment_tokenization 
				end
			end

			self:increment()
			if self:peek() == "]" then return self:split("LONG_COMMENT") end
			::continue_long_comment_tokenization::
		end
	end
end

function Lexer:tokenize_whitespace()
	while self:match_whitespace(self:peek(2)) do
		self:increment()
	end
	return self:split('WS')
end

function Lexer:tokenize_number()
	while self:match_number(self:peek(2)) do
		self:increment()
	end
	return self:split('NUMBER')
end

function Lexer:tokenize_short_comment()
	while self:match_all_except_newline(self:peek(2)) do
		self:increment()
	end
	return self:split('SHORT_COMMENT')
end

function Lexer:match_whitespace( char )
	return char and char:match( "[\t ]" ) ~= nil
end

function Lexer:match_all_except_newline( char )
	return char and char:match( "[^\n\r]" ) ~= nil
end

function Lexer:match_identifier_start( char )
	return char and char:match( "[%a_]" ) ~= nil
end

function Lexer:match_identifier( char )
	return char and char:match( "[%w_%.:]" ) ~= nil
end

function Lexer:match_quote( char )
	return char and char:match( "['\"]" ) ~= nil
end

function Lexer:match_number( char )
	return char and char:match( "[0-9xXp%.i%-a-fA-F]" ) ~= nil
end

function Lexer:match_decimal( char )
	return char and char:match( "[0-9]" ) ~= nil
end

function Lexer:peek(x)
	local peek_length = 0
	if x then peek_length = x - 1 end
	if (self.cursor_end + peek_length) > #self.file then 
		return false 
	else
		return self.file:sub(self.cursor_end + peek_length, self.cursor_end + peek_length)
	end
end

function Lexer:peek_chain(x)
	local peek_length = 0
	if x then peek_length = x - 1 end
	if (self.cursor_end + peek_length) > #self.file then 
		return false 
	else
		return self.file:sub(self.cursor_end, self.cursor_end + peek_length)
	end
end

function Lexer:increment(x)
	local increment_length = 0
	if x then increment_length = x - 1 end
	
	self.cursor_end = self.cursor_end + 1 + increment_length
	return not self:eof(x)
end

function Lexer:eof(x)
	local eof_length = 0
	if x then eof_length = x - 1 end
	return (self.cursor_end + eof_length) > #self.file
end

function Lexer:split(type)
	local token = self.file:sub(self.cursor_start, self.cursor_end)

	self.cursor_end   = self.cursor_end + 1
	self.cursor_start = self.cursor_end
	
	table.insert(self.tokens, {type = type or "_", token = token})
	return token
end

function Lexer:get_current_token()
	return self.file:sub(self.cursor_start, self.cursor_end)
end

return Lexer
