# p4rs3r

Parser project for Lua 5.1 without any depedency.

The parser has multiple phases, for now : 

1/ Lexer:       file string   -> tokens
2/ Preparser:   tokens        -> better tokens
3/ Parser:      better tokens -> ast
4/ Stringifier: ast           -> new file string
?/ Validator


The idea is also to try to make some custom syntax like switch statement, ternary operator, += ...

It's made for learning purpose and the code will try to be as self explainatory as possible, but also maybe lazy sometimes, so use with caution.
