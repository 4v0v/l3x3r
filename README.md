# p4rs3r

Lua Parser / Transpiler / Generator project for  without any depedency.

The parser has multiple phases, for now : 

- 1/ Lexer:       lua w/ custom syntax -> tokens
- 2/ Preparser:   tokens               -> better tokens
- 3/ Parser:      better tokens        -> ast
- 4/ Transformer: ast                  -> lua 5.1 ast

- Validator ?


It will follow the AST like https://github.com/andremm/lua-parser

The idea is also to try to make some custom syntax like ** switch statement, ternary operator, += **

It's made for learning purpose and the code will try to be as self explainatory as possible, but also maybe lazy sometimes, so use with caution.
