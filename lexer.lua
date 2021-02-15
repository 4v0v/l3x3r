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
	elseif self:match_decimal(peek_1) or (peek_1 == '.' and self:match_decimal(peek_2)) then 
		return self:tokenize_number()

	-- simple string
	elseif self:match_quote(peek_1) then 
		return self:tokenize_simple_string()

	-- long string
	elseif chain_2 == '[[' or chain_2 == '[=' then 
		return self:tokenize_long_string()

	-- simple comment 
	elseif (chain_2 == '--' and peek_3 ~= '[') or (chain_3 == '--[' and peek_4 ~= '[' and peek_4 ~= '=') then
		return self:tokenize_short_comment()

	-- long comment && one case of simple comment
	elseif chain_3 == '--[' and (peek_4 == '[' or peek_4 == '=') then 
		return self:tokenize_simple_or_long_comment()

	elseif chain_2 == '::' and self:match_identifier_start(peek_3) then 
		return self:tokenize_label()

	-- symbol
	elseif chain_3 == '...' then self:increment(2) return self:split('...')
	elseif chain_3 == '..=' then self:increment(2) return self:split('..=') -- custom
	elseif chain_2 == '=='  then self:increment()  return self:split('==')
	elseif chain_2 == '>='  then self:increment()  return self:split('>=')	
	elseif chain_2 == '<='  then self:increment()  return self:split('<=')
	elseif chain_2 == '~='  then self:increment()  return self:split('~=')
	elseif chain_2 == '..'  then self:increment()  return self:split('..')
	elseif chain_2 == '>>'  then self:increment()  return self:split('>>')
	elseif chain_2 == '<<'  then self:increment()  return self:split('<<')
	elseif chain_2 == '::'  then self:increment()  return self:split('::')
	elseif chain_2 == '+='  then self:increment()  return self:split('+=') -- custom
	elseif chain_2 == '-='  then self:increment()  return self:split('-=') -- custom
	elseif chain_2 == '!='  then self:increment()  return self:split('!=') -- custom
	elseif chain_2 == '*='  then self:increment()  return self:split('*=') -- custom
	elseif chain_2 == '/='  then self:increment()  return self:split('/=') -- custom
	elseif chain_2 == '%='  then self:increment()  return self:split('%=') -- custom
	elseif chain_2 == '++'  then self:increment()  return self:split('++') -- custom
	elseif chain_2 == '&&'  then self:increment()  return self:split('&&') -- custom
	elseif chain_2 == '||'  then self:increment()  return self:split('||') -- custom
	elseif peek_1  == '['   then                   return self:split('[')
	elseif peek_1  == ']'   then                   return self:split(']')
	elseif peek_1  == '('   then                   return self:split('(')
	elseif peek_1  == ')'   then                   return self:split(')')
	elseif peek_1  == '{'   then                   return self:split('{')
	elseif peek_1  == '}'   then                   return self:split('}')
	elseif peek_1  == '>'   then                   return self:split('>')
	elseif peek_1  == '<'   then                   return self:split('<')
	elseif peek_1  == '='   then                   return self:split('=')
	elseif peek_1  == '%'   then                   return self:split('%')
	elseif peek_1  == '?'   then                   return self:split('?')
	elseif peek_1  == ':'   then                   return self:split(':')
	elseif peek_1  == ';'   then                   return self:split(';')
	elseif peek_1  == ','   then                   return self:split(',')
	elseif peek_1  == '+'   then                   return self:split('+')
	elseif peek_1  == '-'   then                   return self:split('-')
	elseif peek_1  == '*'   then                   return self:split('*')
	elseif peek_1  == '/'   then                   return self:split('/')
	elseif peek_1  == '^'   then                   return self:split('^')
	elseif peek_1  == '#'   then                   return self:split('#')
	elseif peek_1  == '&'   then                   return self:split('&')
	elseif peek_1  == '.'   then                   return self:split('.')
	elseif peek_1  == '\n'  then                   return self:split('\\n')
	elseif peek_1  == '\r'  then                   return self:split('\\r')        
	elseif peek_1  == '@'   then                   return self:split('@') -- custom
	elseif peek_1  == '!'   then                   return self:split('!') -- custom

	-- if nothing match, one char is returned
	else
		return self:split('???')
	end
end

function Lexer:tokenize_simple_string()
	local quote = self:peek()

	self:increment()
	while true do
		local chars = self:peek_chain(2)
		if     chars == [[\\]]         then self:increment()
		elseif chars == [[\]] .. quote then self:increment(2) end

		if self:peek() == quote  then return self:split('S_STRING') end
		if self:peek() == '\n'   then error('invalid short string') end
		if not self:increment()  then error('oef short string ')    end
	end
end

function Lexer:tokenize_keyword_or_identifier()
	while self:match_identifier(self:peek(2)) do
		self:increment()
	end

	local token = self:get_current_token()
	-- default lua keywords
	if token == 'if'       then return self:split('IF')		 end
	if	token == 'then'     then return self:split('THEN')		 end
	if	token == 'else'     then return self:split('ELSE')		 end
	if	token == 'elseif'   then return self:split('ELSEIF')	 end
	if	token == 'end'      then return self:split('END')		 end
	if	token == 'do'       then return self:split('DO')		 end
	if	token == 'for'      then return self:split('FOR')		 end
	if	token == 'function' then return self:split('FUNCTION') end
	if	token == 'repeat'   then return self:split('REPEAT')	 end
	if	token == 'until'    then return self:split('UNTIL')	 end
	if	token == 'while'    then return self:split('WHILE')	 end
	if	token == 'break'    then return self:split('BREAK')	 end
	if	token == 'return'   then return self:split('RETURN')	 end
	if	token == 'local'    then return self:split('LOCAL')	 end
	if	token == 'in'       then return self:split('IN')		 end
	if	token == 'not'      then return self:split('NOT')		 end
	if	token == 'and'      then return self:split('AND')		 end
	if	token == 'or'       then return self:split('OR')		 end
	if	token == 'goto'     then return self:split('GOTO')		 end
	if	token == 'self'     then return self:split('SELF')		 end
	if	token == 'true'     then return self:split('TRUE')		 end
	if	token == 'false'    then return self:split('FALSE')	 end
	if	token == 'nil'      then return self:split('NIL')		 end

	if	token == 'fn'       then return self:split('FN')		 end -- custom
	if	token == 'ifor'     then return self:split('IFOR')		 end -- custom
	if	token == 'rfor'     then return self:split('RFOR')		 end -- custom
	if	token == 'elif'     then return self:split('ELIF')		 end -- custom
	if	token == 'switch'   then return self:split('SWITCH')	 end -- custom
	if	token == 'case'     then return self:split('CASE')		 end -- custom
	
	return self:split('IDENTIFIER')
end

function Lexer:tokenize_long_string()
	local counter = 0

	self:increment()
	if self:peek() == '=' then
		while true  do
			if self:peek() == '=' then 
				counter = counter + 1 
				if not self:increment() then error('invalid long string') end
			elseif self:peek() == '[' then 
				break
			else 
				error( 'invalid long string') 
			end
		end
	end

	if self:peek() == '[' then
		while true do
			if self:eof() then error('invalid long string') end

			self:increment()
			if self:peek() == ']' then
				for i = 1, counter do
					self:increment()
					if  self:peek() ~= '=' then goto continue_longstring_increment end
				end

				self:increment()
				if self:peek() == ']' then return self:split('LONG_STRING') end
				::continue_longstring_increment::
			end
		end
	end
end

function Lexer:tokenize_simple_or_long_comment()
	self:increment(3)
	
	local counter = 0
	if self:peek() == '=' then
		while true  do
			if self:peek() == '=' then
				counter = counter + 1
				self:increment()
			elseif self:peek() == '[' then 
				break
			else   
				return self:tokenize_short_comment()
			end
		end
	end

	while true do
		if self:eof() then error('invalid long comment') end

		self:increment()
		if self:peek() == ']' then
			for i = 1, counter do
				self:increment()
				if  self:peek() ~= '=' then 
					goto continue_long_comment_tokenization 
				end
			end

			self:increment()
			if self:peek() == ']' then return self:split('LONG_COMMENT') end
			::continue_long_comment_tokenization::
		end
	end
end

function Lexer:tokenize_whitespace()
	while self:match_whitespace(self:peek(2)) do
		self:increment()
	end
	return self:split('\\ws')
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

function Lexer:tokenize_label()
	self:increment(2) -- skip ::

	while self:match_label(self:peek(2)) do
		self:increment()
	end
	self:increment()
	
	if self:peek_chain(2) ~= '::' then error('invalid label') end

	self:increment()
	return self:split('LABEL')
end

function Lexer:match_whitespace(char)
	return char and char:match('[\t ]')
end

function Lexer:match_all_except_newline(char)
	return char and char:match('[^\n\r]')
end

function Lexer:match_identifier_start(char)
	return char and char:match('[%a_]')
end

function Lexer:match_label(char)
	return char and char:match('[%w_]')
end

function Lexer:match_identifier(char)
	return char and char:match('[%w_%.:]')
end

function Lexer:match_quote(char)
	return char and char:match('[\'"]')
end

function Lexer:match_number(char)
	return char and char:match('[0-9xXp%.i%-a-fA-F]')
end

function Lexer:match_decimal(char)
	return char and char:match('[0-9]')
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
	
	table.insert(self.tokens, {type = type, token = token})
	return token
end

function Lexer:get_current_token()
	return self.file:sub(self.cursor_start, self.cursor_end)
end

return Lexer
