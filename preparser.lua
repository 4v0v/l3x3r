local Preparser = {}

function Preparser:preparse(tokens)
	self.tokens = tokens
	self.cursor = 1

	-- do stuff on tokens that don't need ast for now
	self:merge_identifiers()
	self:parse_increment()
	self:parse_for_loops()
	self:parse_compound_assignment_operators()

	self:parse_functions()

	return self.tokens
end

function Preparser:parse_functions()
	while not self:eot() do
		self:find_recursive_block_end()
	end
	self.cursor = 1
end


function Preparser:find_recursive_block_end()
	if self:peek('FUNCTION') or self:peek('DO') or self:peek('IF') then
		local block_start = self.cursor

		self:next()

		while not self:eot() do
			if self:peek('END') then 
				local block_end = self.cursor
				print('block start at: '.. block_start .. ' and close at: ' .. block_end)
				return
			end
			
			self:find_recursive_block_end()
		end

		error('CANT FIND END IN BLOC THAT START AT ' .. block_start)
	end

	self:next()
end


function Preparser:parse_compound_assignment_operators()
	while not self:eot() do
		self:next()
	end
	self.cursor = 1
end

function Preparser:parse_for_loops()
	while not self:eot() do

		if self:peek('FOR') then
			if self:peek_next_type_no_ws()  == 'IDENTIFIER' and
				self:peek_next_type_no_ws(2) == 'DO'
			then
				local _, id_pos = self:peek_next_type_no_ws()
				local _, do_pos = self:peek_next_type_no_ws(2)

				for i = self.cursor, do_pos do
					table.remove(self.tokens, self.cursor)
				end
					

				table.insert(self.tokens, self.cursor, {type = "DO"        , value = "do"})
				table.insert(self.tokens, self.cursor, {type = "WHITESPACE", value = "\x20"})
				table.insert(self.tokens, self.cursor, {type = ")"         , value = ")"})
				table.insert(self.tokens, self.cursor, {type = "IDENTIFIER", value = self:get_token_at(id_pos).value})
				table.insert(self.tokens, self.cursor, {type = "("         , value = "("})
				table.insert(self.tokens, self.cursor, {type = "IDENTIFIER", value = "pairs"})
				table.insert(self.tokens, self.cursor, {type = "WHITESPACE", value = "\x20"})
				table.insert(self.tokens, self.cursor, {type = "IN"        , value = "in"})
				table.insert(self.tokens, self.cursor, {type = "WHITESPACE", value = "\x20"})
				table.insert(self.tokens, self.cursor, {type = "IDENTIFIER", value = "it"})
				table.insert(self.tokens, self.cursor, {type = "WHITESPACE", value = "\x20"})
				table.insert(self.tokens, self.cursor, {type = ","         , value = ","})
				table.insert(self.tokens, self.cursor, {type = "IDENTIFIER", value = "key"})
				table.insert(self.tokens, self.cursor, {type = "WHITESPACE", value = "\x20"})
				table.insert(self.tokens, self.cursor, {type = "FOR"       , value = "for"})

			end
		end



		if self:peek('IFOR') then

		end


		if self:peek('RFOR') then

		end

		self:next()
	end
	self.cursor = 1
end

function Preparser:merge_identifiers()
	while not self:eot() do
		if self:peek('IDENTIFIER') then
			local id_start      = self.cursor
			local need_to_merge = false

			while self:peek_next_type_no_ws() == '.' or 
					self:peek_next_type_no_ws() == ':' or
					self:peek_next_type_no_ws() == '[' 
			do
				if need_to_merge == false then
					need_to_merge = true
				end

				if self:peek_next_type_no_ws() == '.' or 
					self:peek_next_type_no_ws() == ':' 
				then
					local next_type, next_pos = self:peek_next_type_no_ws(2)
					if next_type == 'IDENTIFIER' then
						self.cursor = next_pos
					else
						error('BAD IDENTIFIER')
					end

				elseif self:peek_next_type_no_ws() == '[' then
					local next_type            = self:peek_next_type_no_ws(2)
					local next_type2, next_pos = self:peek_next_type_no_ws(3)

					if (next_type == 'STRING' or next_type == 'NUMBER') and next_type2 == ']' then
						self.cursor = next_pos
					else
						error('BAD IDENTIFIER')
					end
				end
			end

			if need_to_merge then
				local new_value = ''
				for i = self.cursor, id_start + 1, -1 do
					new_value = self:get_token_at(i).value .. new_value
					table.remove(self.tokens, i)
				end

				self.cursor = id_start
				self:peek().value = self:peek().value .. new_value
			end
		end

		self:next()
	end
	self.cursor = 1
end

function Preparser:parse_increment()
	while not self:eot() do
		if self:peek('IDENTIFIER') then
			local next_token, next_pos = self:peek_next_no_ws()

			if next_token and next_token.value == "++" then
				local current_token = self:peek()

				table.remove(self.tokens, next_pos) -- remove ++
				table.insert(self.tokens, next_pos, {type = "NUMBER",     value = "1"})
				table.insert(self.tokens, next_pos, {type = "+",          value = "+"})
				table.insert(self.tokens, next_pos, {type = "IDENTIFIER", value = current_token.value})
				table.insert(self.tokens, next_pos, {type = "=",          value = "="})
			end
		end

		self:next()
	end
	self.cursor = 1
end


function Preparser:next()
	self.cursor = self.cursor + 1
end

function Preparser:eot()
	return self.cursor > #self.tokens
end

function Preparser:peek(type)
	if type then
		return type == self.tokens[self.cursor].type
	end
	return self.tokens[self.cursor]
end

function Preparser:get_token_at(number)
	if number > #self.tokens or number < 1 then 
		return false
	else
		return self.tokens[number]
	end
end

function Preparser:peek_next(number)
	local token_pos = self.cursor + (number or 1)
	if token_pos > #self.tokens then 
		return false
	else
		return self.tokens[token_pos]
	end
end

function Preparser:peek_next_no_ws(number)
	local token_pos = self.cursor + 1
	local count     = number or 1

	while token_pos <= #self.tokens do
		if self:get_token_at(token_pos) and 
			self:get_token_at(token_pos).type ~= "WHITESPACE"
		then
			count = count - 1
			if count == 0 then return self:get_token_at(token_pos), token_pos end
		end
		token_pos = token_pos + 1
	end

	return false
end

function Preparser:peek_next_type_no_ws(number)
	local token, pos = self:peek_next_no_ws(number)
	if token then
		return token.type, pos
	else
		return false
	end
end

return Preparser
