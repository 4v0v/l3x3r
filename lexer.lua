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


	for i = 1, #token do
		if token:sub(i, i) == "\t" then 
			self.current_line = self.current_line + 1
		end
	end

	table.insert(self.tokens, token)
	return token
end

function Lexer:is_eof(x)
	local eof_length = 0
	if x then eof_length = x - 1 end
	return (self.cursor_end + eof_length) > #self.file
end


---
---
---

function match_whitespace( char )
	return char:match( "[%s]" ) ~= nil
end

function match_all_except_newline( char )
	return char:match( "[^\n]" ) ~= nil
end

function match_identifier_start( char )
	return char:match( "[%a_]" ) ~= nil
end

function match_identifier( char )
	return char:match( "[%w_%.:]" ) ~= nil
end

function match_quote( char )
	return char:match( "['\"]" ) ~= nil
end

function match_number( char )
	return char:match( "[0-9xXp%.i%-a-fA-F]" ) ~= nil
end

function match_decimal( char )
	return char:match( "[0-9]" ) ~= nil
end

function do_while(input, func)
	local current_char = input:peek()
	if not current_char or not func(current_char) then return end

	while not input:is_eof() and input:peek(2) and func(input:peek(2)) do
		input:increment()
	end
	
	return input:split()
end


-- TODO
function tokenized_longstring()
end

-- TODO
function tokenized_comment()
end

local function tokenize(input)
	do_while(input, match_whitespace)

	--TODO: unary operators: '& '>' etc

	local chars = input:peek_chain(3)
	if     chars == "..=" then input:increment(3) return input:split()
	elseif chars == "..." then input:increment(3) return input:split() end

	local chars = input:peek_chain(2)
	if     chars == "==" then input:increment(2) return input:split()
	elseif chars == ">=" then input:increment(2) return input:split()
	elseif chars == "<=" then input:increment(2) return input:split()
	elseif chars == "+=" then input:increment(2) return input:split()
	elseif chars == "-=" then input:increment(2) return input:split()
	elseif chars == "!=" then input:increment(2) return input:split()
	elseif chars == "~=" then input:increment(2) return input:split()
	elseif chars == "*=" then input:increment(2) return input:split()
	elseif chars == "/=" then input:increment(2) return input:split()
	elseif chars == "==" then input:increment(2) return input:split()
	elseif chars == "++" then input:increment(2) return input:split()
	elseif chars == ".." then input:increment(2) return input:split()
	elseif chars == "&&" then input:increment(2) return input:split()
	elseif chars == "||" then input:increment(2) return input:split()
	elseif chars == ">>" then input:increment(2) return input:split()
	elseif chars == "<<" then input:increment(2) return input:split()
	elseif chars == "::" then input:increment(2) return input:split() end

	local char = input:peek()

	if not char then return end

	--identifiers
	if match_identifier_start(char) then 
		return do_while(input, match_identifier )
	end

	-- number
	if match_decimal(char) then 
		return do_while(input, match_number)
	end

	-- simple string
	if match_quote( char ) then
		input:increment()

		while true do
			local chars = input:peek_chain(2)

			if     chars == "\\\\"       then input:increment()
			elseif chars == "\\" .. char then input:increment(2) end

			if input:peek() == char  then return input:split()    end
			if input:peek() == "\n"  then error("invalid string") end
			if not input:increment() then error("invalid string") end
		end
	end

	-- longstrings
	if char == "[" then
		input:increment()
		
		-- calculate longstring matching length: '[====[' == 4
		local counter = 0
		if input:peek() == "=" then
			while true  do
				if     input:peek() == "[" then 
					break
				elseif input:peek() == "=" then
					counter = counter + 1
					input:increment()
				else   
					error( "invalid long string") 
				end
			end
		end

		-- input:increment() 

		-- beginning of longstring body
		if input:peek() == "[" then
			while true do
				if input:is_eof() then error("invalid long string") end

				input:increment()
				if input:peek() == "]" then
					for i = 1, counter do
						input:increment()
						if  input:peek() ~= "=" then goto continue_longstring_increment end
					end

					input:increment()
					if input:peek() == "]" then return input:split() end
					::continue_longstring_increment::
				end
			end
		else
			-- TODO: identifier like x["test"]
			-- prendre en compte x[' dfs df s @@@']
		end
	end

	-- comments
	local chars = input:peek_chain(2)

	if chars == "--" then
		input:increment(2)
	
		if input:peek() ~= "[" then
			return do_while(input, match_all_except_newline)
		else
			input:increment()
			
			-- calculate longstring matching length: '[====[' == 4
			local counter = 0
			if input:peek() == "=" then
				while true  do
					if     input:peek() == "[" then 
						break
					elseif input:peek() == "=" then
						counter = counter + 1
						input:increment()
					else   
						return do_while(input, match_all_except_newline)
					end
				end
			end

			if input:peek() ~= "[" then
				return do_while(input, match_all_except_newline)
			else
				-- beginning of longcomment body
				while true do
					if input:is_eof() then error("invalid long comment") end

					input:increment()
					if input:peek() == "]" then
						for i = 1, counter do
							input:increment()
							if  input:peek() ~= "=" then goto continue_longcomment_increment end
						end

						input:increment()
						if input:peek() == "]" then return input:split() end
						::continue_longcomment_increment::
					end
				end
			end
		end
	end

	-- if nothing match, one char is returned
	return input:split()
end

function lexer(file, filename)

	local input = Lexer:new(file, filename)

	while not input:is_eof() do
		tokenize(input)
	end

	return input.tokens
end
