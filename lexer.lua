local Lexer = {}

function Lexer:tokenize(file)
	self.file         = file
	self.cursor_start = 1
	self.cursor_end   = 1
	self.tokens       = {}

	while not self:eof() do
		if     self:try_tokenize_whitespace()    then 
		elseif self:try_tokenize_identifier()    then -- contains keywords tokenization
		elseif self:try_tokenize_number()        then 
		elseif self:try_tokenize_short_string()  then 
		elseif self:try_tokenize_long_string()   then 
		elseif self:try_tokenize_short_comment() then
		elseif self:try_tokenize_long_comment()  then -- contains a case of short comment
		elseif self:try_tokenize_label()         then 
		elseif self:try_tokenize_symbol()        then
		else   self:split('???')                 end  -- if nothing match, one char is returned as the token
	end

	return self.tokens
end

function Lexer:try_tokenize_short_string()
	if not self:match_quote(self:peek()) then 
		return false 
	end

	local quote = self:peek()

	self:increment()

	while true do
		local chars = self:peek_chain(2)
		if     chars == [[\\]]         then self:increment()
		elseif chars == [[\]] .. quote then self:increment() self:increment() end

		if self:peek(quote) then 
			self:split('S_STRING') 
			return true 
		end

		self:increment()

		if self:eof() or self:peek('\n') then 
			error('can\'t find end of short string')
		end
	end
end

function Lexer:try_tokenize_identifier()
	if not self:match_identifier_start(self:peek()) then 
		return false
	end

	while self:match_identifier(self:peek(2)) do
		self:increment()
	end

	local token = self:get_current_token()
	if token == 'if'       then self:split('IF')       return true end
	if	token == 'then'     then self:split('THEN')     return true end
	if	token == 'else'     then self:split('ELSE')     return true end
	if	token == 'elseif'   then self:split('ELSEIF')   return true end
	if	token == 'end'      then self:split('END')      return true end
	if	token == 'do'       then self:split('DO')       return true end
	if	token == 'for'      then self:split('FOR')      return true end
	if	token == 'function' then self:split('FUNCTION') return true end
	if	token == 'repeat'   then self:split('REPEAT')   return true end
	if	token == 'until'    then self:split('UNTIL')    return true end
	if	token == 'while'    then self:split('WHILE')    return true end
	if	token == 'break'    then self:split('BREAK')    return true end
	if	token == 'return'   then self:split('RETURN')   return true end
	if	token == 'local'    then self:split('LOCAL')    return true end
	if	token == 'in'       then self:split('IN')       return true end
	if	token == 'not'      then self:split('NOT')      return true end
	if	token == 'and'      then self:split('AND')      return true end
	if	token == 'or'       then self:split('OR')       return true end
	if	token == 'goto'     then self:split('GOTO')     return true end
	if	token == 'self'     then self:split('SELF')     return true end
	if	token == 'true'     then self:split('TRUE')     return true end
	if	token == 'false'    then self:split('FALSE')    return true end
	if	token == 'nil'      then self:split('NIL')      return true end
	if	token == 'fn'       then self:split('FN')       return true end -- custom
	if	token == 'ifor'     then self:split('IFOR')     return true end -- custom
	if	token == 'rfor'     then self:split('RFOR')     return true end -- custom
	if	token == 'elif'     then self:split('ELIF')     return true end -- custom
	if	token == 'switch'   then self:split('SWITCH')   return true end -- custom
	if	token == 'case'     then self:split('CASE')     return true end -- custom
	if	token == 'continue' then self:split('CONTINUE') return true end -- custom
	if	token == 'through'  then self:split('THROUGH')  return true end -- custom

	self:split('IDENTIFIER')
	return true
end

function Lexer:try_tokenize_symbol()
	local peek_1  = self:peek()
	local chain_2 = self:peek_chain(2)
	local chain_3 = self:peek_chain(3)

	if chain_3 == '...' then self:increment() self:increment() self:split('...') return true end
	if chain_3 == '..=' then self:increment() self:increment() self:split('..=') return true end -- custom
	if chain_2 == '=='  then self:increment() self:split('==') return true end
	if chain_2 == '>='  then self:increment() self:split('>=') return true end
	if chain_2 == '<='  then self:increment() self:split('<=') return true end
	if chain_2 == '~='  then self:increment() self:split('~=') return true end
	if chain_2 == '..'  then self:increment() self:split('..') return true end
	if chain_2 == '>>'  then self:increment() self:split('>>') return true end
	if chain_2 == '<<'  then self:increment() self:split('<<') return true end
	if chain_2 == '::'  then self:increment() self:split('::') return true end
	if chain_2 == '+='  then self:increment() self:split('+=') return true end -- custom
	if chain_2 == '-='  then self:increment() self:split('-=') return true end -- custom
	if chain_2 == '!='  then self:increment() self:split('!=') return true end -- custom
	if chain_2 == '*='  then self:increment() self:split('*=') return true end -- custom
	if chain_2 == '/='  then self:increment() self:split('/=') return true end -- custom
	if chain_2 == '%='  then self:increment() self:split('%=') return true end -- custom
	if chain_2 == '++'  then self:increment() self:split('++') return true end -- custom
	if chain_2 == '&&'  then self:increment() self:split('&&') return true end -- custom
	if chain_2 == '||'  then self:increment() self:split('||') return true end -- custom
	if peek_1  == '['   then self:split('[')    return true end
	if peek_1  == ']'   then self:split(']')    return true end
	if peek_1  == '('   then self:split('(')    return true end
	if peek_1  == ')'   then self:split(')')    return true end
	if peek_1  == '{'   then self:split('{')    return true end
	if peek_1  == '}'   then self:split('}')    return true end
	if peek_1  == '>'   then self:split('>')    return true end
	if peek_1  == '<'   then self:split('<')    return true end
	if peek_1  == '='   then self:split('=')    return true end
	if peek_1  == '%'   then self:split('%')    return true end
	if peek_1  == '?'   then self:split('?')    return true end
	if peek_1  == ':'   then self:split(':')    return true end
	if peek_1  == ';'   then self:split(';')    return true end
	if peek_1  == ','   then self:split(',')    return true end
	if peek_1  == '+'   then self:split('+')    return true end
	if peek_1  == '-'   then self:split('-')    return true end
	if peek_1  == '*'   then self:split('*')    return true end
	if peek_1  == '/'   then self:split('/')    return true end
	if peek_1  == '^'   then self:split('^')    return true end
	if peek_1  == '#'   then self:split('#')    return true end
	if peek_1  == '&'   then self:split('&')    return true end
	if peek_1  == '.'   then self:split('.')    return true end
	if peek_1  == '\n'  then self:split('eol')  return true end
	if peek_1  == '\r'  then self:split('eolr') return true end       
	if peek_1  == '@'   then self:split('@')    return true end -- custom
	if peek_1  == '!'   then self:split('!')    return true end -- custom
	
	return false 
end

function Lexer:try_tokenize_long_string()
	if self:peek_chain(2) ~= '[[' and self:peek_chain(2) ~= '[=' then
		return false
	end

	-- skip '[' 
	self:increment()

	-- count '='
	local counter = 0
	if self:peek('=') then
		while true do
			if self:peek('=') then 
				counter = counter + 1 
				self:increment()
				if self:eof() then error('can\'t find long string end') end
			elseif self:peek('[') then 
				break
			else 
				error('incorrect syntax on long string declaration') 
			end
		end
	end

	while true do
		if self:eof() then error('can\'t find long string end') end

		self:increment()

		if self:peek(']') then
			for i = 1, counter do
				self:increment()
				if not self:peek('=') then goto continue_tokenization end
			end

			self:increment()

			if self:peek(']') then 
				self:split('LONG_STRING') 
				return true
			end

			::continue_tokenization::
		end
	end
end

function Lexer:try_tokenize_long_comment()
   if self:peek_chain(3) ~= '--[' or (self:peek(4) ~= '[' and self:peek(4) ~= '=') then
		return false
	end

	-- skip '--['
	self:increment()
	self:increment()
	self:increment()
	
	-- count '='
	local counter = 0
	if self:peek('=') then
		while true  do
			if self:peek('=')  then
				counter = counter + 1
				self:increment()
			elseif self:peek('[') then 
				break
			else 
				-- it's a short comment
				while self:match_all_except_newline(self:peek(2)) do
					self:increment()
				end

				self:split('SHORT_COMMENT') 
				return true
			end
		end
	end

	-- tokenize until end of comment
	while true do
		if self:eof() then error('invalid long comment') end

		self:increment()

		if self:peek(']') then
			for i = 1, counter do
				self:increment()
				if not self:peek('=') then goto continue_tokenization end
			end

			self:increment()

			if self:peek(']') then 
				self:split('LONG_COMMENT') 
				return true 
			end

			::continue_tokenization::
		end
	end
end

function Lexer:try_tokenize_whitespace()
	if not self:match_whitespace(self:peek()) then 
		return false 
	end

	while self:match_whitespace(self:peek(2)) do
		self:increment()
	end

	self:split('wsp')
	return true
end

function Lexer:try_tokenize_number()
	if not self:match_decimal(self:peek()) and 
		not (self:peek() == '.' and self:match_decimal(self:peek(2))) 
	then
		return false
	end

	while self:match_number(self:peek(2)) do
		self:increment()
	end

	self:split('NUMBER')
	return true
end

function Lexer:try_tokenize_short_comment()
	if not (self:peek_chain(2) == '--'  and self:peek(3) ~= '[') and 
		not (self:peek_chain(3) == '--[' and self:peek(4) ~= '[' and self:peek(4) ~= '=')
	then
		return false
	end

	while self:match_all_except_newline(self:peek(2)) do
		self:increment()
	end

	self:split('SHORT_COMMENT')
	return true
end

function Lexer:try_tokenize_label()
	if self:peek_chain(2) ~= '::' or not self:match_identifier_start(self:peek(3)) then
		return false
	end

	-- skip '::'
	self:increment() 
	self:increment()

	while self:match_label(self:peek()) do
		self:increment()
	end
	
	if self:peek_chain(2) ~= '::' then error('invalid label') end

	self:increment()
	self:split('LABEL')
	return true
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

function Lexer:peek(a)
	if type(a) == 'string' then
		if #a > 1 then error('can\'t peek more than 1 letter') end
		return a == self.file:sub(self.cursor_end, self.cursor_end)
	end

	local peek_length = 0
	if a then peek_length = a - 1 end
	if (self.cursor_end + peek_length) > #self.file then 
		return false 
	else
		return self.file:sub(self.cursor_end + peek_length, self.cursor_end + peek_length)
	end
end

function Lexer:peek_chain(a)
	local peek_length = 0
	if a then peek_length = a - 1 end
	if (self.cursor_end + peek_length) > #self.file then 
		return false 
	else
		return self.file:sub(self.cursor_end, self.cursor_end + peek_length)
	end
end

function Lexer:increment()
	self.cursor_end = self.cursor_end + 1
end

function Lexer:eof()
	return self.cursor_end > #self.file
end

function Lexer:split(type)
	table.insert(self.tokens, {
		type  = type, 
		token = self.file:sub(self.cursor_start, self.cursor_end)
	})
	self:increment()
	self.cursor_start = self.cursor_end
end

function Lexer:get_current_token()
	return self.file:sub(self.cursor_start, self.cursor_end)
end

return Lexer
