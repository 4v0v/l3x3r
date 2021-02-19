local Lexer = {}

function Lexer:tokenize(file)
	self.file         = file
	self.cursor_start = 1
	self.cursor_end   = 1
	self.line         = 1
	self.tokens       = {}

	while not self:eof() do
		if     self:try_whitespace()    then 
		elseif self:try_identifier()    then -- contains keywords tokenization
		elseif self:try_number()        then 
		elseif self:try_short_string()  then 
		elseif self:try_long_string()   then 
		elseif self:try_short_comment() then
		elseif self:try_long_comment()  then -- contains a case of short comment
		elseif self:try_label()         then 
		elseif self:try_symbol()        then
		else   error("UNDEFINED TOKEN") end  -- if nothing match token is one char
	end

	return self.tokens
end

function Lexer:insert_token(type, value)
	local value      = value or self:get_current_token()
	local line_start = self.line

	for i = 1, #value do
		if value:sub(i, i) == '\n' then
			self.line = self.line + 1
		end
	end

	table.insert(self.tokens, {
		type       = type, 
		value      = value,
		pos_start  = self.cursor_start,
		pos_end    = self.cursor_end,
		line_start = line_start,
		line_end   = self.pos,
	})

	self:next()
	self.cursor_start = self.cursor_end
end

function Lexer:peek(string)
	if string then
		return string == self.file:sub(self.cursor_end, self.cursor_end + #string - 1)
	end

	if self.cursor_end > #self.file then 
		return false 
	else
		return self.file:sub(self.cursor_end, self.cursor_end)
	end
end

function Lexer:peek_next(number)
	local char_pos = self.cursor_end + (number or 1)

	if char_pos > #self.file then 
		return false 
	else
		return self.file:sub(char_pos, char_pos)
	end
end

function Lexer:next(number)
	self.cursor_end = self.cursor_end + (number or 1)
end

function Lexer:eof()
	return self.cursor_end > #self.file
end

function Lexer:try_identifier()
	if not self:match_identifier_start(self:peek()) then 
		return false
	end

	while self:match_identifier(self:peek_next()) do
		self:next()
	end

	local token = self:get_current_token()
	if	token == 'fn'       then self:insert_token('FUNCTION', 'function') return true end -- custom
	if	token == 'elif'     then self:insert_token('ELSEIF'  , 'elseif')   return true end -- custom
	if	token == 'rfor'     then self:insert_token('RFOR'    , 'for')      return true end -- custom
	if	token == 'ifor'     then self:insert_token('IFOR'    , 'for')      return true end -- custom
	if token == 'if'       then self:insert_token('IF')                   return true end
	if	token == 'then'     then self:insert_token('THEN')                 return true end
	if	token == 'else'     then self:insert_token('ELSE')                 return true end
	if	token == 'elseif'   then self:insert_token('ELSEIF')               return true end
	if	token == 'end'      then self:insert_token('END')                  return true end
	if	token == 'do'       then self:insert_token('DO')                   return true end
	if	token == 'for'      then self:insert_token('FOR')                  return true end
	if	token == 'function' then self:insert_token('FUNCTION')             return true end
	if	token == 'repeat'   then self:insert_token('REPEAT')               return true end
	if	token == 'until'    then self:insert_token('UNTIL')                return true end
	if	token == 'while'    then self:insert_token('WHILE')                return true end
	if	token == 'break'    then self:insert_token('BREAK')                return true end
	if	token == 'return'   then self:insert_token('RETURN')               return true end
	if	token == 'local'    then self:insert_token('LOCAL')                return true end
	if	token == 'in'       then self:insert_token('IN')                   return true end
	if	token == 'not'      then self:insert_token('NOT')                  return true end
	if	token == 'and'      then self:insert_token('AND')                  return true end
	if	token == 'or'       then self:insert_token('OR')                   return true end
	if	token == 'goto'     then self:insert_token('GOTO')                 return true end
	if	token == 'self'     then self:insert_token('IDENTIFIER')           return true end
	if	token == 'true'     then self:insert_token('TRUE')                 return true end
	if	token == 'false'    then self:insert_token('FALSE')                return true end
	if	token == 'nil'      then self:insert_token('NIL')                  return true end

	self:insert_token('IDENTIFIER')
	return true
end

function Lexer:try_symbol()
	if     self:peek('&&')  then self:next()  self:insert_token('AND'       , '\x20and\x20') -- custom
	elseif self:peek('||')  then self:next()  self:insert_token('OR'        , '\x20or\x20')  -- custom
	elseif self:peek('@')   then              self:insert_token('IDENTIFIER', 'self') -- custom
	elseif self:peek('!')   then              self:insert_token('NOT'       , '\x20not\x20') -- custom
	elseif self:peek('..=') then self:next(2) self:insert_token('..=') -- custom
	elseif self:peek('+=')  then self:next()  self:insert_token('+=') -- custom
	elseif self:peek('-=')  then self:next()  self:insert_token('-=') -- custom
	elseif self:peek('*=')  then self:next()  self:insert_token('*=') -- custom
	elseif self:peek('/=')  then self:next()  self:insert_token('/=') -- custom
	elseif self:peek('%=')  then self:next()  self:insert_token('%=') -- custom
	elseif self:peek('!=')  then self:next()  self:insert_token('~=') -- custom
	elseif self:peek('==')  then self:next()  self:insert_token('==')
	elseif self:peek('>=')  then self:next()  self:insert_token('>=')
	elseif self:peek('<=')  then self:next()  self:insert_token('<=')
	elseif self:peek('~=')  then self:next()  self:insert_token('~=')
	elseif self:peek('...') then self:next(2) self:insert_token('...') -- '...' this must be before ''..''
	elseif self:peek('..')  then self:next()  self:insert_token('..')  -- '...' this must be before ''..''
	elseif self:peek('>')   then              self:insert_token('>')
	elseif self:peek('<')   then              self:insert_token('<')
	elseif self:peek('=')   then              self:insert_token('=')
	elseif self:peek('[')   then              self:insert_token('[')
	elseif self:peek(']')   then              self:insert_token(']')
	elseif self:peek('(')   then              self:insert_token('(')
	elseif self:peek(')')   then              self:insert_token(')')
	elseif self:peek('{')   then              self:insert_token('{')
	elseif self:peek('}')   then              self:insert_token('}')
	elseif self:peek(':')   then              self:insert_token(':')
	elseif self:peek('.')   then              self:insert_token('.')
	elseif self:peek(';')   then              self:insert_token(';')
	elseif self:peek(',')   then              self:insert_token(',')
	elseif self:peek('%')   then              self:insert_token('%')
	elseif self:peek('+')   then              self:insert_token('+')
	elseif self:peek('-')   then              self:insert_token('-')
	elseif self:peek('*')   then              self:insert_token('*')
	elseif self:peek('/')   then              self:insert_token('/')
	elseif self:peek('^')   then              self:insert_token('^')
	elseif self:peek('#')   then              self:insert_token('#')
	else return false end

	return true 
end

function Lexer:try_whitespace()
	if not self:match_whitespace(self:peek()) then 
		return false 
	end

	while self:match_whitespace(self:peek_next()) do
		self:next()
	end

	self:insert_token('WHITESPACE')
	return true
end

function Lexer:try_number()
	if not self:match_decimal(self:peek()) and 
		not (self:peek() == '.' and self:match_decimal(self:peek_next())) 
	then
		return false
	end

	while self:match_number(self:peek_next()) do
		self:next()
	end

	self:insert_token('NUMBER')
	return true
end

function Lexer:try_short_comment()
	if not (self:peek('--') and self:peek_next(2) ~= '[') and 
		not (self:peek('--[') and self:peek_next(3) ~= '[' and self:peek_next(3) ~= '=')
	then
		return false
	end

	while not self:match_newline(self:peek_next()) do
		self:next()
	end

	self:insert_token('COMMENT')
	return true
end

function Lexer:try_label()
	if not self:peek('::') or not self:match_identifier_start(self:peek_next(2)) then
		return false
	end

	-- skip '::'
	self:next(2)

	while self:match_identifier(self:peek()) do
		self:next()
	end
	
	if not self:peek('::') then error('INVALID LABEL') end

	self:next()
	self:insert_token('LABEL')
	return true
end

function Lexer:try_short_string()
	if not self:match_quote(self:peek()) then 
		return false 
	end

	local quote = self:peek()

	-- tokenize until end of line
	while true do
		self:next()

		if self:eof() or self:peek('\n') then 
			error('INVALID STRING')
		end

		if     self:peek([[\\]])         then self:next()
		elseif self:peek([[\]] .. quote) then self:next(2) end

		if self:peek(quote) then 
			self:insert_token('STRING') 
			return true 
		end
	end
end

function Lexer:try_long_string()
	if not self:peek('[[') and not self:peek('[=') then
		return false
	end

	-- skip '[' 
	self:next()

	-- count '='
	local counter = 0
	if self:peek('=') then
		while true do
			if self:peek('=') then 
				counter = counter + 1 
				self:next()
				if self:eof() then error('INVALID LONG STRING') end
			elseif self:peek('[') then 
				break
			else 
				error('INVALID LONG STRING') 
			end
		end
	end

	while true do
		if self:eof() then error('INVALID LONG STRING') end

		self:next()

		if self:peek(']') then
			for i = 1, counter do
				self:next()
				if not self:peek('=') then 
					-- '=' count is too low
					goto continue_tokenization 
				end
			end

			if self:peek_next() == ']' then
				self:next()
				self:insert_token('STRING') 
				return true
			end

			::continue_tokenization::
		end
	end
end

function Lexer:try_long_comment()
   if not self:peek('--[') or (self:peek_next(3) ~= '[' and self:peek_next(3) ~= '=') then
		return false
	end

	-- skip '--['
	self:next(3)
	
	-- count '='
	local counter = 0
	if self:peek('=') then
		while true  do
			if self:peek('=')  then
				counter = counter + 1
				self:next()
			elseif self:peek('[') then 
				break
			else 
				-- it's a short comment
				while not self:match_newline(self:peek_next()) do
					self:next()
				end

				self:insert_token('COMMENT') 
				return true
			end
		end
	end

	-- tokenize until end of comment
	while true do
		if self:eof() then error('INVALID LONG COMMENT') end

		self:next()

		if self:peek(']') then
			for i = 1, counter do
				self:next()
				if not self:peek('=') then 
					-- '=' count is too low
					goto continue_tokenization 
				end
			end

			if self:peek_next() == ']' then
				self:next()
				self:insert_token('COMMENT') 
				return true
			end

			::continue_tokenization::
		end
	end
end

function Lexer:get_current_token()
	return self.file:sub(self.cursor_start, self.cursor_end)
end

function Lexer:match_whitespace(char)
	return char and char:match('[\n\t\x20]')
end

function Lexer:match_newline(char)
	return char and char:match('[\n]')
end

function Lexer:match_identifier_start(char)
	return char and char:match('[%a_]')
end

function Lexer:match_identifier(char)
	return char and char:match('[%w_]')
end

function Lexer:match_quote(char)
	return char and char:match('[\'"]')
end

-- TODO: 2+e00 scientific notation
function Lexer:match_number(char)
	return char and char:match('[%-%x%.xX]')  
end

function Lexer:match_decimal(char)
	return char and char:match('[%d]')
end

return Lexer
