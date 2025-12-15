package parser

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:math"
import "core:mem"
import "core:os"
import "core:os/os2"
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

TokenData :: struct #raw_union {
        str : string,
        num : f32,
}

Token :: struct {
        type : TokenType,
        data : TokenData
}

TokenizationError :: enum {
        EmptyFile,
}

ParsingError :: enum {
        EmptySymbol,

        UnexpectedToken,

        UnexpectedTokenAtSymbolName,

        InSufficientPrimitiveData,

        FailureToPraseLineCoord,

        UnexpectedTokenTypeAtPrimitivePropertyName,
        UnexpectedValueAtPrimitivePropertyName,
        UnexpectedTokenTypeAtPrimitivePropertyValue,
}


tokenize :: proc (str : string) -> (tokens : [] Token, err : union { TokenizationError, mem.Allocator_Error }= nil) {
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

        if len(tempTokens) < 1 {
                err = .EmptyFile
                delete(tempTokens)
                return
        }

        tokens = tempTokens[:]
	return
}

parse :: proc (str : string) -> (symbol : types.Symbol, err : union { TokenizationError, ParsingError, mem.Allocator_Error} = nil) {
        tokens, tokenizationError := tokenize(str)

        switch te in tokenizationError {
        case TokenizationError:
                err = te 
                return
        case runtime.Allocator_Error:
                err = te
                return
        }

        if tokens[0].type != .String {
                err = .UnexpectedTokenAtSymbolName
                return
        }

        name, strCloneErr := strings.clone(tokens[0].data.str)

        if strCloneErr != .None {
                err = strCloneErr
                return 
        }

        symbol.name = name

        if ! (len(tokens) > 1) {
                err = .EmptySymbol
        }

        primitives : [dynamic] types.Primitive
        idx := 1
        for idx < len(tokens) {
                switch tokens[idx].type{
                case .String:
                        str := tokens[idx].data.str 
                        switch {
                        case strings.compare(str, "Line") == 0:
                                primitive, nextTokenIdx, primitiveErr := parseLinePrimitive(&tokens, idx)
                                if primitiveErr != nil {
                                        err = primitiveErr
                                        return
                                }
                                idx = nextTokenIdx
                                append(&primitives, primitive)
                        case strings.compare(str, "Spline") == 0:
                                primitive, nextTokenIdx, primitiveErr := parseSplinePrimitive(&tokens, idx)
                                if primitiveErr != nil {
                                        err = primitiveErr
                                        return
                                }
                                idx = nextTokenIdx
                                append(&primitives, primitive)
                        case strings.compare(str, "Triangle") == 0:
                                primitive, nextTokenIdx, primitiveErr := parseTrianglePrimitive(&tokens, idx)
                                if primitiveErr != nil {
                                        err = primitiveErr
                                        return
                                }
                                idx = nextTokenIdx
                                append(&primitives, primitive)
                        case strings.compare(str, "Rectangle ") == 0:
                                primitive, nextTokenIdx, primitiveErr := parseRectanglePrimitive(&tokens, idx)
                                if primitiveErr != nil {
                                        err = primitiveErr
                                        return
                                }
                                idx = nextTokenIdx
                                append(&primitives, primitive)
                        case strings.compare(str, "RoundedRectangle") == 0:
                                primitive, nextTokenIdx, primitiveErr := parseRoundedRectanglePrimitive(&tokens, idx)
                                if primitiveErr != nil {
                                        err = primitiveErr
                                        return
                                }
                                idx = nextTokenIdx
                                append(&primitives, primitive)
                        case strings.compare(str, "Circle") == 0:
                                primitive, nextTokenIdx, primitiveErr := parseCirclePrimitive(&tokens, idx)
                                if primitiveErr != nil {
                                        err = primitiveErr
                                        return
                                }
                                idx = nextTokenIdx
                                append(&primitives, primitive)
                        case strings.compare(str, "Sector") == 0:
                                primitive, nextTokenIdx, primitiveErr := parseSectorPrimitive(&tokens, idx)
                                if primitiveErr != nil {
                                        err = primitiveErr
                                        return
                                }
                                idx = nextTokenIdx
                                append(&primitives, primitive)
                        case strings.compare(str, "Arc") == 0:
                                primitive, nextTokenIdx, primitiveErr := parseArcPrimitive(&tokens, idx)
                                if primitiveErr != nil {
                                        err = primitiveErr
                                        return
                                }
                                idx = nextTokenIdx
                                append(&primitives, primitive)
                        case strings.compare(str, "Ring") == 0:
                                primitive, nextTokenIdx, primitiveErr := parseRingPrimitive(&tokens, idx)
                                if primitiveErr != nil {
                                        err = primitiveErr
                                        return
                                }
                                idx = nextTokenIdx
                                append(&primitives, primitive)
                        case strings.compare(str, "Polygon") == 0:
                                primitive, nextTokenIdx, primitiveErr := parsePolygonPrimitive(&tokens, idx)
                                if primitiveErr != nil {
                                        err = primitiveErr
                                        return
                                }
                                idx = nextTokenIdx
                                append(&primitives, primitive)
                        case:
                                err = .UnexpectedToken
                                return
                        } 
                case .Number:
                        err = .UnexpectedToken
                        return
                }

                fmt.printfln("Primvitive: %V", primitives[len(primitives)-1])
        }

        symbol.primitives = primitives[:]

	return
}




parseLinePrimitive ::proc (tokens : ^ [] Token, idx : int) -> (primitive : types.Primitive, nextTokenIndex : int, err : ParsingError = nil) {
        nextTokenIndex = idx 
        primitive.type = .Line
        lineCoord : [4] f32

        for i in 1..=4 {
                if tokens[nextTokenIndex + i].type == .Number {
                        lineCoord[i-1] = tokens[nextTokenIndex + i].data.num
                } else {
                        err = .UnexpectedTokenTypeAtPrimitivePropertyValue
                        return
                }
        }

        primitive.line.p0.x = lineCoord[0]
        primitive.line.p0.y = lineCoord[1]
        primitive.line.p1.x = lineCoord[2]
        primitive.line.p1.y = lineCoord[3]

        // checking we get the correct property name
        if tokens[nextTokenIndex + 5].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 5].data.str, "strokeThickness") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }


        // checking we get the property value
        if tokens[nextTokenIndex + 6].type != .Number {
                err = .UnexpectedTokenTypeAtPrimitivePropertyValue
        }

        primitive.line.strokeThickness = tokens[nextTokenIndex + 6].data.num

        // checking we get the correct property name
        if tokens[nextTokenIndex + 7].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 7].data.str, "strokeColor") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }

        for i in 8..=11 {
                if tokens[nextTokenIndex + i].type == .Number {
                        lineCoord[i-8] = tokens[nextTokenIndex + i].data.num
                } else {
                        err = .UnexpectedTokenTypeAtPrimitivePropertyValue
                        return
                }
        }
        primitive.line.strokeColor = {auto_cast lineCoord[0], auto_cast lineCoord[1], auto_cast lineCoord[2], auto_cast lineCoord[3]}
        nextTokenIndex += 12

        return
}

parseSplinePrimitive ::proc (tokens : ^ [] Token, idx : int) -> (primitive : types.Primitive, nextTokenIndex : int, err : ParsingError = nil) {
        return
}


parseTrianglePrimitive ::proc (tokens : ^ [] Token, idx : int) -> (primitive : types.Primitive, nextTokenIndex : int, err : ParsingError = nil) {
        nextTokenIndex = idx 
        primitive.type = .Triangle
        triangleCoord : [6] f32

        for i in 1..=6 {
                if tokens[nextTokenIndex + i].type == .Number {
                        triangleCoord[i-1] = tokens[nextTokenIndex + i].data.num
                } else {
                        err = .UnexpectedTokenTypeAtPrimitivePropertyValue
                        return
                }
        }

        primitive.triangle.p0.x = triangleCoord[0]
        primitive.triangle.p0.y = triangleCoord[1]
        primitive.triangle.p1.x = triangleCoord[2]
        primitive.triangle.p1.y = triangleCoord[3]
        primitive.triangle.p2.x = triangleCoord[4]
        primitive.triangle.p2.y = triangleCoord[5]

        // checking we get the correct property name
        if tokens[nextTokenIndex + 7].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 7].data.str, "strokeThickness") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }


        // checking we get the property value
        if tokens[nextTokenIndex + 8].type != .Number {
                err = .UnexpectedTokenTypeAtPrimitivePropertyValue
        }

        primitive.triangle.strokeThickness = tokens[nextTokenIndex + 8].data.num

        // checking we get the correct property name
        if tokens[nextTokenIndex + 9].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 9].data.str, "strokeColor") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }

        for i in 10..=13 {
                if tokens[nextTokenIndex + i].type == .Number {
                        triangleCoord[i-10] = tokens[nextTokenIndex + i].data.num
                } else {
                        err = .UnexpectedTokenTypeAtPrimitivePropertyValue
                        return
                }
        }
        primitive.triangle.strokeColor = {auto_cast triangleCoord[0], auto_cast triangleCoord[1], auto_cast triangleCoord[2], auto_cast triangleCoord[3]}


        // checking we get the correct property name
        if tokens[nextTokenIndex + 14].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 14].data.str, "fillType") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }


        // checking we get the property value
        if tokens[nextTokenIndex + 15].type != .Number {
                err = .UnexpectedTokenTypeAtPrimitivePropertyValue
        }

        primitive.triangle.strokeThickness = tokens[nextTokenIndex + 15].data.num

        // checking we get the correct property name
        if tokens[nextTokenIndex + 16].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 16].data.str, "fillColor") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }

        for i in 17..=20 {
                if tokens[nextTokenIndex + i].type == .Number {
                        triangleCoord[i-17] = tokens[nextTokenIndex + i].data.num
                } else {
                        err = .UnexpectedTokenTypeAtPrimitivePropertyValue
                        return
                }
        }
        primitive.triangle.fillColor = {auto_cast triangleCoord[0], auto_cast triangleCoord[1], auto_cast triangleCoord[2], auto_cast triangleCoord[3]}

        nextTokenIndex += 21

        return
}

parseRectanglePrimitive ::proc (tokens : ^ [] Token, idx : int) -> (primitive : types.Primitive, nextTokenIndex : int, err : ParsingError = nil) {
        return
}

parseRoundedRectanglePrimitive ::proc (tokens : ^ [] Token, idx : int) -> (primitive : types.Primitive, nextTokenIndex : int, err : ParsingError = nil) {
        return
}

parseCirclePrimitive ::proc (tokens : ^ [] Token, idx : int) -> (primitive : types.Primitive, nextTokenIndex : int, err : ParsingError = nil) {
        return
}

parseSectorPrimitive ::proc (tokens : ^ [] Token, idx : int) -> (primitive : types.Primitive, nextTokenIndex : int, err : ParsingError = nil) {
        return
}

parseArcPrimitive ::proc (tokens : ^ [] Token, idx : int) -> (primitive : types.Primitive, nextTokenIndex : int, err : ParsingError = nil) {
        return
}

parseRingPrimitive ::proc (tokens : ^ [] Token, idx : int) -> (primitive : types.Primitive, nextTokenIndex : int, err : ParsingError = nil) {
        return
}

parsePolygonPrimitive ::proc (tokens : ^ [] Token, idx : int) -> (primitive : types.Primitive, nextTokenIndex : int, err : ParsingError = nil) {
        return
}
