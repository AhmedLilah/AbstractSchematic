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
import "../transform"


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
        using data : TokenData
}

TokenizationError :: enum {
        EmptyFile,
}

ParsingError :: enum {
        EmptySymbol,

        UnexpectedToken,

        UnexpectedTokenAtSymbolName,

        InSufficientPrimitiveData,

        FailureToParseLineCoord,

        UnexpectedTokenTypeAtPrimitivePropertyName,
        UnexpectedValueAtPrimitivePropertyName,
        UnexpectedTokenTypeAtPrimitivePropertyValue,
}


tokenize :: proc (str : string) -> (tokens : [] Token, err : union { TokenizationError, mem.Allocator_Error }= nil) {
        tempTokens         : [dynamic] Token
	runeArray          : [dynamic] rune
        currentToken       :  Token

        defer delete(runeArray)

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
                        }
                        clear(&runeArray)
		} else {
                        isTokenStart = true
                        if len(runeArray) > 0 {
                                if currentToken.type == .String {
                                        currentToken.str = utf8.runes_to_string(runeArray[:])
                                } else if currentToken.type == .Number{
                                        currentToken.num, _ = strconv.parse_f32(utf8.runes_to_string(runeArray[:]))
                                }
                                append_elem(&tempTokens, currentToken)
                        }
                        clear(&runeArray)
		}
	}

        if len(tempTokens) < 1 {
                err = .EmptyFile
                return
        }

        tokens = tempTokens[:]
	return
}

parse :: proc (str : string) -> (symbol : types.Symbol, err : union { TokenizationError, ParsingError, mem.Allocator_Error} = nil) {
        tokens, tokenizationError := tokenize(str)

        defer {
                for &token in tokens {
                        #partial switch token.type {
                        case .String:
                                delete(token.str)     
                        }
                }
                delete(tokens)
        }


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

        name, strCloneErr := strings.clone(tokens[0].str)

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
                        case strings.compare(str, "Rectangle") == 0:
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

        primitive.triangle.fillType = cast(types.FillType) cast(int) tokens[nextTokenIndex + 14].data.num

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
        nextTokenIndex = idx 
        primitive.type = .Rectangle
        rectangleCoord : [4] f32

        for i in 1..=4 {
                if tokens[nextTokenIndex + i].type == .Number {
                        rectangleCoord[i-1] = tokens[nextTokenIndex + i].data.num
                } else {
                        err = .UnexpectedTokenTypeAtPrimitivePropertyValue
                        return
                }
        }

        primitive.rectangle.pos.x = rectangleCoord[0]
        primitive.rectangle.pos.y = rectangleCoord[1]
        primitive.rectangle.size.x = rectangleCoord[2]
        primitive.rectangle.size.y = rectangleCoord[3]

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

        primitive.rectangle.strokeThickness = tokens[nextTokenIndex + 6].data.num

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
                        rectangleCoord[i-8] = tokens[nextTokenIndex + i].data.num
                } else {
                        err = .UnexpectedTokenTypeAtPrimitivePropertyValue
                        return
                }
        }
        primitive.rectangle.strokeColor = {auto_cast rectangleCoord[0], auto_cast rectangleCoord[1], auto_cast rectangleCoord[2], auto_cast rectangleCoord[3]}


        // checking we get the correct property name
        if tokens[nextTokenIndex + 12].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 12].data.str, "fillType") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }


        // checking we get the property value
        if tokens[nextTokenIndex + 13].type != .Number {
                err = .UnexpectedTokenTypeAtPrimitivePropertyValue
        }

        primitive.rectangle.fillType = cast(types.FillType) cast(int) tokens[nextTokenIndex + 13].data.num

        // checking we get the correct property name
        if tokens[nextTokenIndex + 14].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 14].data.str, "fillColor") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }

        for i in 15..=18 {
                if tokens[nextTokenIndex + i].type == .Number {
                        rectangleCoord[i-15] = tokens[nextTokenIndex + i].data.num
                } else {
                        err = .UnexpectedTokenTypeAtPrimitivePropertyValue
                        return
                }
        }
        primitive.rectangle.fillColor = {auto_cast rectangleCoord[0], auto_cast rectangleCoord[1], auto_cast rectangleCoord[2], auto_cast rectangleCoord[3]}

        nextTokenIndex += 19

        return
}

parseRoundedRectanglePrimitive ::proc (tokens : ^ [] Token, idx : int) -> (primitive : types.Primitive, nextTokenIndex : int, err : ParsingError = nil) {
        nextTokenIndex = idx 
        primitive.type = .RoundedRectangle
        roundedRectangleCoord : [5] f32

        for i in 1..=5 {
                if tokens[nextTokenIndex + i].type == .Number {
                        roundedRectangleCoord[i-1] = tokens[nextTokenIndex + i].data.num
                } else {
                        err = .UnexpectedTokenTypeAtPrimitivePropertyValue
                        return
                }
        }

        primitive.roundedRectangle.pos.x = roundedRectangleCoord[0]
        primitive.roundedRectangle.pos.y = roundedRectangleCoord[1]
        primitive.roundedRectangle.size.x = roundedRectangleCoord[2]
        primitive.roundedRectangle.size.y = roundedRectangleCoord[3]
        primitive.roundedRectangle.radius = roundedRectangleCoord[4]

        // checking we get the correct property name
        if tokens[nextTokenIndex + 6].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 6].data.str, "strokeThickness") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }


        // checking we get the property value
        if tokens[nextTokenIndex + 7].type != .Number {
                err = .UnexpectedTokenTypeAtPrimitivePropertyValue
        }

        primitive.roundedRectangle.strokeThickness = tokens[nextTokenIndex + 7].data.num

        // checking we get the correct property name
        if tokens[nextTokenIndex + 8].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 8].data.str, "strokeColor") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }

        for i in 9..=12 {
                if tokens[nextTokenIndex + i].type == .Number {
                        roundedRectangleCoord[i-9] = tokens[nextTokenIndex + i].data.num
                } else {
                        err = .UnexpectedTokenTypeAtPrimitivePropertyValue
                        return
                }
        }
        primitive.roundedRectangle.strokeColor = {auto_cast roundedRectangleCoord[0], auto_cast roundedRectangleCoord[1], auto_cast roundedRectangleCoord[2], auto_cast roundedRectangleCoord[3]}


        // checking we get the correct property name
        if tokens[nextTokenIndex + 13].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 13].data.str, "fillType") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }


        // checking we get the property value
        if tokens[nextTokenIndex + 14].type != .Number {
                err = .UnexpectedTokenTypeAtPrimitivePropertyValue
        }

        primitive.roundedRectangle.fillType = cast(types.FillType) cast(int) tokens[nextTokenIndex + 14].data.num

        // checking we get the correct property name
        if tokens[nextTokenIndex + 15].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 15].data.str, "fillColor") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }

        for i in 16..=19 {
                if tokens[nextTokenIndex + i].type == .Number {
                        roundedRectangleCoord[i-16] = tokens[nextTokenIndex + i].data.num
                } else {
                        err = .UnexpectedTokenTypeAtPrimitivePropertyValue
                        return
                }
        }
        primitive.roundedRectangle.fillColor = {auto_cast roundedRectangleCoord[0], auto_cast roundedRectangleCoord[1], auto_cast roundedRectangleCoord[2], auto_cast roundedRectangleCoord[3]}

        nextTokenIndex += 20

        return
}

parseCirclePrimitive ::proc (tokens : ^ [] Token, idx : int) -> (primitive : types.Primitive, nextTokenIndex : int, err : ParsingError = nil) {
        nextTokenIndex = idx 
        primitive.type = .Circle
        circleCoord : [4] f32

        for i in 1..=3 {
                if tokens[nextTokenIndex + i].type == .Number {
                        circleCoord[i-1] = tokens[nextTokenIndex + i].data.num
                } else {
                        err = .UnexpectedTokenTypeAtPrimitivePropertyValue
                        return
                }
        }

        primitive.circle.center.x = circleCoord[0]
        primitive.circle.center.y = circleCoord[1]
        primitive.circle.radius   = circleCoord[2]

        // checking we get the correct property name
        if tokens[nextTokenIndex + 4].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 4].data.str, "strokeThickness") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }


        // checking we get the property value
        if tokens[nextTokenIndex + 5].type != .Number {
                err = .UnexpectedTokenTypeAtPrimitivePropertyValue
        }

        primitive.circle.strokeThickness = tokens[nextTokenIndex + 5].data.num

        // checking we get the correct property name
        if tokens[nextTokenIndex + 6].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 6].data.str, "strokeColor") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }

        for i in 7..=10 {
                if tokens[nextTokenIndex + i].type == .Number {
                        circleCoord[i-7] = tokens[nextTokenIndex + i].data.num
                } else {
                        err = .UnexpectedTokenTypeAtPrimitivePropertyValue
                        return
                }
        }
        primitive.circle.strokeColor = {auto_cast circleCoord[0], auto_cast circleCoord[1], auto_cast circleCoord[2], auto_cast circleCoord[3]}


        // checking we get the correct property name
        if tokens[nextTokenIndex + 11].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 11].data.str, "fillType") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }


        // checking we get the property value
        if tokens[nextTokenIndex + 12].type != .Number {
                err = .UnexpectedTokenTypeAtPrimitivePropertyValue
        }

        primitive.circle.fillType = cast(types.FillType) cast(int) tokens[nextTokenIndex + 12].data.num

        // checking we get the correct property name
        if tokens[nextTokenIndex + 13].type != .String {
                err = .UnexpectedTokenTypeAtPrimitivePropertyName
                return
        }

        if  strings.compare(tokens[nextTokenIndex + 13].data.str, "fillColor") != 0 {
                err = .UnexpectedValueAtPrimitivePropertyName
                return
        }

        for i in 14..=17 {
                if tokens[nextTokenIndex + i].type == .Number {
                        circleCoord[i-14] = tokens[nextTokenIndex + i].data.num
                } else {
                        err = .UnexpectedTokenTypeAtPrimitivePropertyValue
                        return
                }
        }
        primitive.circle.fillColor = {auto_cast circleCoord[0], auto_cast circleCoord[1], auto_cast circleCoord[2], auto_cast circleCoord[3]}

        nextTokenIndex += 18

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
