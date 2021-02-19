local Preparser = {}

Preparser.OPERATORS_UNARY = {
	['-']=1, ['NOT']=1, ['#']=1
}
Preparser.OPERATORS_BINARY = {
	['+']=1, ['-']=1, ['*']=1, ['/']=1, ['^']=1, ['%']=1, ['..']=1,
	['<']=1, ['<=']=1, ['>']=1, ['>=']=1, ['==']=1, ['~=']=1,
	['AND']=1, ['OR']=1,
}
Preparser.OPERATORS_COMPOUND = {
	['+=']=1, ['-=']=1, ['*=']=1, ['/=']=1, ['^=']=1, ['%=']=1, ['..=']=1,
}
Preparser.BLOCK_START = {
	['FUNCTION']=1, ['DO']=1, ['IF']=1, ['(']=1, ['{']=1,
}

function Preparser:preparse(tokens)
	self.tokens = tokens
	self.cursor = 1

	self:merge_identifiers()
	self:parse_compound_assignment_operators()
	self:parse_for_loops()

	return self.tokens
end

function Preparser:merge_identifiers()
	while not self:eot() do
		if self:peek('IDENTIFIER') then
			local id_start      = self.cursor
			local need_to_merge = false

			while self:peek_next_type() == '.' or 
					self:peek_next_type() == ':' or
					self:peek_next_type() == '[' 
			do
				if not need_to_merge then
					need_to_merge = true
				end

				if self:peek_next_type() == '.' or self:peek_next_type() == ':' then
					local next_type, next_pos = self:peek_next_type(2)
					if next_type == 'IDENTIFIER' then
						self.cursor = next_pos
					else
						error('BAD IDENTIFIER')
					end

				else
					local next_type , _        = self:peek_next_type(2)
					local next_type2, next_pos = self:peek_next_type(3)

					if (next_type == 'STRING' or next_type == 'NUMBER') and next_type2 == ']' then
						self.cursor = next_pos
					else
						error('BAD IDENTIFIER')
					end
				end
			end

			if need_to_merge then
				local merged_identifier = ''
				for i = self.cursor, id_start + 1, -1 do
					merged_identifier = self:get_token_at(i).value .. merged_identifier
					table.remove(self.tokens, i)
				end

				self.cursor       = id_start
				self:peek().value = self:peek().value .. merged_identifier
			end
		end

		self:next()
	end
	self.cursor = 1
end

function Preparser:parse_compound_assignment_operators()
	while not self:eot() do
		if self:peek('IDENTIFIER') and self.OPERATORS_COMPOUND[self:peek_next_type()] then

			local assigned_identifier = self:peek().value
			local _, compound_pos     = self:peek_next_type()
			local compound_operator   = self:get_token_at(compound_pos).value:sub(1, 1)
			local assignment_start    = compound_pos + 1

			self.cursor = compound_pos -- enter inside assignment

			while true do
				-- pass through unary operators of assigment member if there is any
				while self.OPERATORS_UNARY[self:peek_next_type()] do
					local _, pos = self:peek_next_type()
					self.cursor  = pos 
				end

				-- pass through assigment member
				if self:peek_next_type() == 'IDENTIFIER' or self:peek_next_type() == 'NUMBER' then
					local _, pos = self:peek_next_type()
					self.cursor  = pos -- identifier

				elseif self:peek_next_type() == '(' or self:peek_next_type() == '{' then
					local _, pos = self:peek_next_type()
					self.cursor  = pos -- go to block start

					local block = self:find_recursive_block()
					self.cursor = block.block_end

				else
					error('INVALID ASSIGMENT')
				end

				-- pass through assigment member call if there is any
				if self:peek_next_type() == '(' then
					local _, pos = self:peek_next_type()
					self.cursor  = pos

					local block = self:find_recursive_block()
					self.cursor = block.block_end
				end

				-- pass through operator if there is any, if not then it's the end of the assignment
				if self.OPERATORS_BINARY[self:peek_next_type()] then
					local _, pos = self:peek_next_type()
					self.cursor  = pos
				else
					break
				end
			end

			table.insert(self.tokens, self.cursor + 1,   {type = ')', value = ')'}) -- assigment end
			table.insert(self.tokens, assignment_start, {type = '(', value = '('})
			table.insert(self.tokens, assignment_start, {type = compound_operator, value = compound_operator})
			table.insert(self.tokens, assignment_start, {type = 'IDENTIFIER', value = assigned_identifier})

			self.tokens[compound_pos].type  = '='
			self.tokens[compound_pos].value = '='
		end

		self:next()
	end
	self.cursor = 1
end


function Preparser:find_recursive_block(recursive_block)
	if not self.BLOCK_START[self:peek().type] then
		self:next()
	else
		local block = {
			blocks      = {},
			block_type  = self:peek().type, 
			block_start = self.cursor
		}

		self:next() -- move in block body

		while not self:eot() do
			if block.block_type == '{' and self:peek('}') or
				block.block_type == '(' and self:peek(')') or
				self:peek('END') 
			then
				block['block_end'] = self.cursor
				self:next()

				if recursive_block then
					table.insert(recursive_block, block)
					return recursive_block
				else
					return block
				end
			end
				
			self:find_recursive_block(block.blocks)
		end

		error('CANT FIND BLOCK END')
	end
end

function Preparser:parse_for_loops()
	while not self:eot() do

		if self:peek('FOR') then
			if self:peek_next_type()  == 'IDENTIFIER' and
				self:peek_next_type(2) == 'DO'
			then
				local _, id_pos = self:peek_next_type()
				local _, do_pos = self:peek_next_type(2)

				for i = self.cursor, do_pos do
					table.remove(self.tokens, self.cursor)
				end
					
				table.insert(self.tokens, self.cursor, {type = 'DO'        , value = 'do'})
				table.insert(self.tokens, self.cursor, {type = 'WHITESPACE', value = '\x20'})
				table.insert(self.tokens, self.cursor, {type = ')'         , value = ')'})
				table.insert(self.tokens, self.cursor, {type = 'IDENTIFIER', value = self:get_token_at(id_pos).value})
				table.insert(self.tokens, self.cursor, {type = '('         , value = '('})
				table.insert(self.tokens, self.cursor, {type = 'IDENTIFIER', value = 'pairs'})
				table.insert(self.tokens, self.cursor, {type = 'WHITESPACE', value = '\x20'})
				table.insert(self.tokens, self.cursor, {type = 'IN'        , value = 'in'})
				table.insert(self.tokens, self.cursor, {type = 'WHITESPACE', value = '\x20'})
				table.insert(self.tokens, self.cursor, {type = 'IDENTIFIER', value = 'it'})
				table.insert(self.tokens, self.cursor, {type = 'WHITESPACE', value = '\x20'})
				table.insert(self.tokens, self.cursor, {type = ','         , value = ','})
				table.insert(self.tokens, self.cursor, {type = 'IDENTIFIER', value = 'key'})
				table.insert(self.tokens, self.cursor, {type = 'WHITESPACE', value = '\x20'})
				table.insert(self.tokens, self.cursor, {type = 'FOR'       , value = 'for'})
			end
		end

		if self:peek('IFOR') then end
		if self:peek('RFOR') then end

		self:next()
	end
	self.cursor = 1
end

function Preparser:get_token_at(number)
	if number > #self.tokens or number < 1 then 
		return false
	else
		return self.tokens[number]
	end
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
	else
		return self.tokens[self.cursor]
	end
end

function Preparser:peek_next_with_whitespace(number)
	local token_pos = self.cursor + (number or 1)
	if token_pos > #self.tokens then 
		return false
	else
		return self.tokens[token_pos]
	end
end

-- no whitespace
function Preparser:peek_next(number)
	local token_pos = self.cursor + 1
	local count     = number or 1

	while token_pos <= #self.tokens do
		if self:get_token_at(token_pos) and 
			self:get_token_at(token_pos).type ~= 'WHITESPACE'
		then
			count = count - 1
			if count == 0 then return self:get_token_at(token_pos), token_pos end
		end
		token_pos = token_pos + 1
	end

	return false
end

-- no whitespace
function Preparser:peek_next_type(number)
	local token, pos = self:peek_next(number)
	if token then
		return token.type, pos
	else
		return false
	end
end

return Preparser

