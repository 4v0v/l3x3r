-- TODO: identifier like x["test"] -- prendre en compte x[' dfs df s @@@']
-- TODO: increment lines
-- TODO: unary operators: '& '>' etc


local Lexer = {}

function Lexer:new(file, filename)
	local obj = {}
	obj.current_line = 1 
	obj.cursor_start = 1
	obj.cursor_end   = 1
	obj.tokens       = {}
	obj.file         = file
	obj.filename     = filename
	return setmetatable(obj, {__index = Lexer})
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

function Lexer:current_token()
	return self.file:sub(self.cursor_start, self.cursor_end)
end

function Lexer:increment(x)
	local increment_length = 0
	if x then increment_length = x - 1 end
	self.cursor_end = self.cursor_end + 1 + increment_length
	return not self:is_eof(x)
end

function Lexer:split()
	local token = self.file:sub(self.cursor_start, self.cursor_end)

	self.cursor_end   = self.cursor_end + 1
	self.cursor_start = self.cursor_end
	--TODO: check if end of file
	table.insert(self.tokens, token)
	return token
end

function Lexer:is_eof(x)
	local eof_length = 0
	if x then eof_length = x - 1 end
	return (self.cursor_end + eof_length) > #self.file
end

function Lexer:match_whitespace( char )
	return char:match( "[%s]" ) ~= nil
end

function Lexer:match_all_except_newline( char )
	return char:match( "[^\n]" ) ~= nil
end

function Lexer:match_identifier_start( char )
	return char:match( "[%a_]" ) ~= nil
end

function Lexer:match_identifier( char )
	return char:match( "[%w_%.:]" ) ~= nil
end

function Lexer:match_quote( char )
	return char:match( "['\"]" ) ~= nil
end

function Lexer:match_number( char )
	return char:match( "[0-9xXp%.i%-a-fA-F]" ) ~= nil
end

function Lexer:match_decimal( char )
	return char:match( "[0-9]" ) ~= nil
end

function Lexer:do_while(func)
	local current_char = self:peek()
	if not current_char or not self[func](self, current_char) then return end

	while not self:is_eof() and self:peek(2) and self[func](self, self:peek(2)) do
		self:increment()
	end
	
	return self:split()
end

function Lexer:tokenize_simple_strings()
	local quote = self:peek()

	self:increment()
	while true do
		local chars = self:peek_chain(2)

		if     chars == "\\\\"        then self:increment()
		elseif chars == "\\" .. quote then self:increment(2) end

		if self:peek() == quote  then return self:split()     end
		if self:peek() == "\n"   then error("invalid string") end
		if not self:increment()  then error("invalid string") end
	end
end


function Lexer:tokenized_long_strings()
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
			if self:is_eof() then error("invalid long string") end

			self:increment()
			if self:peek() == "]" then
				for i = 1, counter do
					self:increment()
					if  self:peek() ~= "=" then goto continue_longstring_increment end
				end

				self:increment()
				if self:peek() == "]" then return self:split() end
				::continue_longstring_increment::
			end
		end
	end
end

function Lexer:tokenized_comments()
	self:increment(2)
	
	if self:peek() ~= "[" then
		return self:do_while('match_all_except_newline')
	else
		self:increment()
		
		-- calculate longstring matching length: '[====[' == 4
		local counter = 0
		if self:peek() == "=" then
			while true  do
				if self:peek() == "=" then
					counter = counter + 1
					self:increment()
				elseif self:peek() == "[" then 
					break
				else   
					return self:do_while('match_all_except_newline')
				end
			end
		end

		if self:peek() ~= "[" then
			return self:do_while('match_all_except_newline')
		else
			-- beginning of longcomment body
			while true do
				if self:is_eof() then error("invalid long comment") end

				self:increment()
				if self:peek() == "]" then
					for i = 1, counter do
						self:increment()
						if  self:peek() ~= "=" then goto continue_longcomment_increment end
					end

					self:increment()
					if self:peek() == "]" then return self:split() end
					::continue_longcomment_increment::
				end
			end
		end
	end
end

function Lexer:tokenize()
	local char = self:peek()

	if not char then return end

	-- whitespace
	if self:match_whitespace(char) then
		return self:do_while('match_whitespace')
	end

	-- identifiers
	if self:match_identifier_start(char) then 
		return self:do_while('match_identifier')
	end

	-- numbers
	if self:match_decimal(char) or (char == "." and self:match_decimal(self:peek(2))) then 
		return self:do_while('match_number')
	end

	-- simple strings
	if self:match_quote( char ) then
		return self:tokenize_simple_strings()
	end

	-- long strings
	if self:peek(2) == "[[" or self:peek(2) == "[=" then
		return self:tokenized_long_strings()
	end

	-- simple && long comments
	if self:peek_chain(2) == "--" then
		return self:tokenized_comments()
	end

	-- symbols
	local chars = self:peek_chain(3)
	if chars == "..=" or
	 	chars == "..." 
	then 
		self:increment(3) 
		return self:split() 
	end

	local chars = self:peek_chain(2)
	if chars == "==" or
		chars == ">=" or
		chars == "<=" or
		chars == "+=" or
		chars == "-=" or
		chars == "!=" or
		chars == "~=" or
		chars == "*=" or
		chars == "/=" or
		chars == "==" or
		chars == "++" or
		chars == ".." or
		chars == "&&" or
		chars == "||" or
		chars == ">>" or
		chars == "<<" or
		chars == "::"
	then
		self:increment(2) 
		return self:split() 
	end
	
	-- if nothing match, one char is returned
	return self:split()
end


return function(file, filename)
	local input = Lexer:new(file, filename)

	while not input:is_eof() do
		input:tokenize()
	end

	return input.tokens
end
