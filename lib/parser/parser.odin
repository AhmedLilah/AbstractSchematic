package parser

import "core:fmt"
import "core:io"
import "core:math"
import "core:os"
import "core:os/os2"
import "base:runtime"
import "core:strings"
import "core:strconv"
import "core:sys/windows"
import "core:unicode"
import "core:unicode/utf8"

import "../types"
import "../draw/draw_helper"


TokenType :: enum { 
        String,
        Number,
}

Token :: struct {
        type : TokenType,
        data : struct #raw_union {
                str : string,
                num : f32,
        }
}

tokenize :: proc (str : string) -> (tokens : [] Token) {
        fmt.println("|\t|--\tstarting tokenization process")
        defer fmt.println("|\t|--\tfinished tokenization process")
        tempTokens         : [dynamic] Token
	runeArray          : [dynamic] rune
        currentToken       :  Token

        isTokenStart       := true
        isComment          := false
        isFirstTokenInLine := true

	for val, idx in str {
		if unicode.is_alpha(val) {
                        if isTokenStart {
                                isTokenStart = false
                                currentToken.type = .String
                        } else if isComment {
                                clear(&runeArray)
                                continue
                        }
			append_elem(&runeArray, val)
		} else if unicode.is_number(val) || val == '-' || val == '.' {
                        if isTokenStart {
                                isTokenStart = false
                                currentToken.type = .Number
                        } else if isComment {
                                clear(&runeArray)
                                continue
                        } else if currentToken.type == .String {
                                append_elem(&runeArray, val)
                                continue
                        }
			append_elem(&runeArray, val)
                } else if val == '/' {
                        if isTokenStart && !isComment {
                                isComment = true
                                isTokenStart = false
                        }
                } else if val == '\n' {
                        isComment = false
                        isTokenStart = true
                        if len(runeArray) > 0 {
                                if currentToken.type == .String {
                                        currentToken.data.str = utf8.runes_to_string(runeArray[:])
                                } else if currentToken.type == .Number{
                                        currentToken.data.num, _ = strconv.parse_f32(utf8.runes_to_string(runeArray[:]))
                                }
                                append_elem(&tempTokens, currentToken)
                                clear(&runeArray)
                        }
		} else {
                        isTokenStart = true
                        if len(runeArray) > 0 {
                                if currentToken.type == .String {
                                        currentToken.data.str = utf8.runes_to_string(runeArray[:])
                                } else if currentToken.type == .Number{
                                        currentToken.data.num, _ = strconv.parse_f32(utf8.runes_to_string(runeArray[:]))
                                }
                                append_elem(&tempTokens, currentToken)
                                clear(&runeArray)
                        }
		}
	}

        tokens = tempTokens[:]
	return
}

parse :: proc (str : string) -> (symbol : types.Symbol) {
        fmt.println("|--\tstarting parsing process")
        defer fmt.println("|--\tfinished parsing process")

        tokens := tokenize(str)

        for token in tokens {
                switch token.type{
                case .String:
                        fmt.printf("|\t|\t|--\ttoken type: %v, token data: %v\n", token.type, token.data.str)
                case .Number:
                        fmt.printf("|\t|\t|--\ttoken type: %v, token data: %v\n", token.type, token.data.num)
                }
        }

	return
}
