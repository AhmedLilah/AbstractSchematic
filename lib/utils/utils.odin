package utils

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

import rl "vendor:raylib"

import "../types"
import "../transform"
import "../parser"
import "../globals"


// @NOTE: solve the EEEEE error problem
// @BUG: when saving symbols the color gets saved showing teh [,] format. 
//      probably because we are using the default formatting.

readLibraryModelFiles :: proc(libraryDirName : string) -> (symbols : [dynamic] types.Symbol) {
        fmt.println("starting library reading")
        defer fmt.println("finished library reading")
	if !os.is_dir(libraryDirName) {
		msg := fmt.tprintf("'%s' isn't a directory.", libraryDirName)
		panic(msg)
	}

	libraryDirHandle, err := os.open(libraryDirName)
	switch _ in err {
	case os.General_Error:
		panic(os.error_string(err))
	case io.Error:
		panic(os.error_string(err))
	case runtime.Allocator_Error:
		panic(os.error_string(err))
	case windows.System_Error:
		panic(os.error_string(err))
	}

	dirContents, dirErr := os.read_dir(libraryDirHandle, -1)

	switch _ in dirErr{
	case os.General_Error:
		panic(os.error_string(err))
	case io.Error:
		panic(os.error_string(err))
	case runtime.Allocator_Error:
		panic(os.error_string(err))
	case windows.System_Error:
		panic(os.error_string(err))
	}

	for fileInfo in dirContents {
		if fileInfo.is_dir {
			msg := fmt.tprintf("'%s' isn't a model-file.", fileInfo.name)
			panic(msg)
		} else {
			file, ok := os.read_entire_file(fileInfo.fullpath)
			if !ok {
				msg := fmt.tprintf("Couldn't read the file '%s'", fileInfo.fullpath)
				panic(msg)
			}

			fileStr := fmt.tprintf("%s", file)
			sym, EEEEE := parser.parse(fileStr)
			append(&symbols, sym)
		}
	}

	return
}

saveSymbolToFile :: proc (name : string, instances : [] types.DrawableInstance) {
	fileName := fmt.tprintf("assets/symbols/basic/%s%s", name, ".sch")

	fileString : strings.Builder
	strings.write_string(&fileString, name)
	strings.write_string(&fileString, " {\n")

	symbolMin: [2] f32 = 1e30

	for instance in instances {
                switch v in instance {
                case types.SymbolInstance:
                        if min := min(symbolMin.x, v.pos.x); min < symbolMin.x {
                                symbolMin = v.pos
                        } else if min == symbolMin.x {
                                if v.pos.y < symbolMin.y {
                                        symbolMin = v.pos
                                }
                        }
                case types.Wire:
                        if min := min(symbolMin.x, v.pos.x); min < symbolMin.x {
                                symbolMin = v.pos
                        } else if min == symbolMin.x {
                                if v.pos.y < symbolMin.y {
                                        symbolMin = v.pos
                                }
                        }
                }
	}

	for instance in instances {
                switch i in instance {
                case types.SymbolInstance:
                        internalSymbolPrimitives := make([] types.Primitive, len(i.primitives))
                        copy(internalSymbolPrimitives, i.primitives)
                        internalInstanceCopy := types.SymbolInstance{types.Symbol{i.name, internalSymbolPrimitives[:]}, i.pos, i.rotation, i.horizontalFlip, i.verticalFlip}

                        // Correction for the inverted monitor Y-Axis
                        transform.flipVertically(&internalInstanceCopy)

                        // Handel Rotation
                        switch i.rotation  {
                        case types.Rotation.East:
                        case .North:
                                transform.rotate(&internalInstanceCopy)
                        case .West:
                                transform.rotate(&internalInstanceCopy)
                                transform.rotate(&internalInstanceCopy)
                        case .South:
                                transform.rotate(&internalInstanceCopy)
                                transform.rotate(&internalInstanceCopy)
                                transform.rotate(&internalInstanceCopy)
                        }

                        // Vertical Flipping
                        if internalInstanceCopy.verticalFlip {
                                transform.flipVertically(&internalInstanceCopy)
                        }

                        // Horizontal Flipping
                        if internalInstanceCopy.horizontalFlip {
                                transform.flipHorizontally(&internalInstanceCopy)
                        }

                        
                        for primitive in internalInstanceCopy.primitives {
                                #partial switch primitive.type {
                                case .Line:
                                        tempString := fmt.tprintf("\tLine %v %v %v %v strokeThickness %v strokeColor %v %v %v %v\n", 
                                                (primitive.line.p0.x + i.pos.x) - symbolMin.x, (primitive.line.p0.y + i.pos.y) - symbolMin.y, 
                                                (primitive.line.p1.x + i.pos.x) - symbolMin.x, (primitive.line.p1.y + i.pos.y ) - symbolMin.y, 
                                                primitive.line.strokeThickness, 
                                                primitive.line.strokeColor.r,
                                                primitive.line.strokeColor.g,
                                                primitive.line.strokeColor.g,
                                                primitive.line.strokeColor.a,
                                        )
                                        strings.write_string(&fileString, tempString)
                                case .Spline:
                                case .Triangle:
                                case .Rectangle:
                                case .RoundedRectangle:
                                case .Circle:
                                case .Sector:
                                case .Arc:
                                case .Ring:
                                case .Polygon:
                                }
                        }
                case types.Wire:
                        for idx in 1..<len(i.points) {
                                p0 := i.points[idx-1]
                                p1 := i.points[idx]

                                line0 : [4] f32 
                                line1 : [4] f32

                                switch {
                                // If vertical
                                case (p1.x - p0.x) == 0:
                                        line0 = {p0.x, p0.y, p1.x, p1.y}
                                        line1 = {p0.x, p0.y, p1.x, p1.y}
                                        // If horizontal
                                case (p1.y - p0.y) == 0:
                                        line0 = {p0.x, p0.y, p1.x, p0.y}
                                        line1 = {p0.x, p0.y, p1.x, p1.y}
                                        // If mostly horizontal
                                case math.abs(p1.x - p0.x) > math.abs(p1.y - p0.y):
                                        line0 = {p0.x, p0.y, p1.x, p0.y}
                                        line1 = {p1.x, p0.y, p1.x,   p1.y}
                                        // If mostly vertical 
                                case math.abs(p1.y - p0.y) > math.abs(p1.x - p0.x):
                                        line0 = {p0.x, p0.y, p0.x, p1.y}
                                        line1 = {p0.x, p1.y, p1.x,   p1.y}
                                        // If diagnal
                                case:
                                        line0 = {p0.x, p0.y, p1.x, p1.y}
                                        line1 = {p0.x, p0.y, p1.x, p1.y}
                                }

                                tempString := fmt.tprintf("\t%v %v %v %v %v\n\t%v %v %v %v %v\n",
                                        (line0.x) - symbolMin.x, (line0.y) - symbolMin.y,
                                        (line0.z) - symbolMin.x, (line0.w) - symbolMin.y,
                                        i.strokeThickness,
                                        (line1.x) - symbolMin.x, (line1.y) - symbolMin.y,
                                        (line1.z) - symbolMin.x, (line1.w) - symbolMin.y,
                                        i.strokeThickness
                                )
                                strings.write_string(&fileString, tempString)
                                fmt.printf("\t%v %v %v %v %v\n\t%v %v %v %v %v\n",
                                        (line0.x) - symbolMin.x, (line0.y) - symbolMin.y,
                                        (line0.z) - symbolMin.x, (line0.w) - symbolMin.y,
                                        i.strokeThickness,
                                        (line1.x) - symbolMin.x, (line1.y) - symbolMin.y,
                                        (line1.z) - symbolMin.x, (line1.w) - symbolMin.y,
                                        i.strokeThickness
                                )
                        }
                }
	} 

	strings.write_string(&fileString, "}\n")

        ////////////////////////////////////////////

 //        tempSymb, EEEEE := parser.parse(strings.to_string(fileString))
 //        transform.flipVertically(&types.SymbolInstance{tempSymb, {0,0}, .East, false, false})
	// tempfileString : strings.Builder
	// strings.write_string(&tempfileString, name)
	// strings.write_string(&tempfileString, " {\n")
 //        for primitive in tempSymb.primitives {
 //                tempString := fmt.tprintf("\tLine %v %v %v %v strokeThickness %v strokeColor %v\n", 
 //                        (primitive.line.p0.x), (primitive.line.p0.y),
 //                        (primitive.line.p1.x), (primitive.line.p1.y),
 //                        primitive.line.strokeThickness, primitive.line.strokeColor
 //                )
 //                strings.write_string(&tempfileString, tempString)
 //        }
	// strings.write_string(&tempfileString, "}\n")
        
        ///////////////////////////////////////////


	file, fileErr := os2.create(fileName)

	switch _ in fileErr {
	case os2.General_Error:
		fmt.printfln("File Creation Error %s", os2.error_string(fileErr))
	case io.Error:
		fmt.printfln("File Creation Error %s", os2.error_string(fileErr))
	case runtime.Allocator_Error:
		fmt.printfln("File Creation Error %s", os2.error_string(fileErr))
	case windows.System_Error:
		fmt.printfln("File Creation Error %s", os2.error_string(fileErr))
	}

	n : int
	n, fileErr = os2.write(file, fileString.buf[:])
        // n, fileErr = os2.write(file, tempfileString.buf[:])

	switch _ in fileErr {
	case os2.General_Error:
		fmt.printfln("File Writing Error %s", os2.error_string(fileErr))
	case io.Error:
		fmt.printfln("File Writing Error %s", os2.error_string(fileErr))
	case runtime.Allocator_Error:
		fmt.printfln("File Writing Error %s", os2.error_string(fileErr))
	case windows.System_Error:
		fmt.printfln("File Writing Error %s", os2.error_string(fileErr))
	}

	fileErr = os2.close(file)

	switch _ in fileErr {
	case os2.General_Error:
		fmt.printfln("File Closing Error %s", os2.error_string(fileErr))
	case io.Error:
		fmt.printfln("File Closing Error %s", os2.error_string(fileErr))
	case runtime.Allocator_Error:
		fmt.printfln("File Closing Error %s", os2.error_string(fileErr))
	case windows.System_Error:
		fmt.printfln("File Closing Error %s", os2.error_string(fileErr))
	}
}


handleGirdOptions :: proc (showGrid : ^ bool, showFineGrid : ^ bool, mouseCoord : ^ [2] f32, mouseGridCoord : ^ [2] f32) {
        if (rl.IsKeyDown(.LEFT_ALT) || rl.IsKeyDown(.RIGHT_ALT)) && rl.IsKeyPressed(.G) {
                showFineGrid^ = !showFineGrid^
        } else if rl.IsKeyPressed(.G) {
                showGrid^ = !showGrid^
        }
        if showFineGrid^ {
                mouseGridCoord^ = {round(mouseCoord.x, globals.DEFAULT_GRID_SIZE/5), round(mouseCoord.y, globals.DEFAULT_GRID_SIZE/5)}
        } else {
                mouseGridCoord^ = {round(mouseCoord.x, globals.DEFAULT_GRID_SIZE), round(mouseCoord.y, globals.DEFAULT_GRID_SIZE)}
        } 
}


calculateGridSize :: proc (showGrid : ^ bool, showFineGrid : ^ bool, gridSize : ^ f32, windowSize : ^ [2] f32, camera : ^ rl.Camera2D) {
                // Hadeling adaptive grid sizing
                if showGrid^ {
                        if 0.2 <= camera.zoom && camera.zoom < 0.75{
                                gridSize^ = globals.DEFAULT_GRID_SIZE * globals.DEFAULT_GRID_SCALING_FACTOR
                        } else if 0.75 <= camera.zoom && camera.zoom < 4 {
                                gridSize^ = globals.DEFAULT_GRID_SIZE
                        } else if  4 <= camera.zoom  && camera.zoom <= 5 {
                                gridSize^ = globals.DEFAULT_GRID_SIZE / globals.DEFAULT_GRID_SCALING_FACTOR
                        }
                }

}


// simple rounding function to help with the grid
round :: proc (number : f32, amount : f32) -> f32 {
	mod := cast(int) (number / amount)
	rem := number - (amount * cast(f32) mod)

	if rem < (amount/2) {
		return (amount * cast(f32) mod)
	} else {
		return (amount * cast(f32) (mod+1))
	}
}


screenCoordinates :: proc(pos: [2]f32, worldPos: [2]f32, screenSize: [2]f32) -> (screenPos: [2]f32) {
	relativePos: [2]f32

	relativePos.x = -1 * (pos.x - worldPos.x)
	relativePos.y = -1 * (pos.y - worldPos.y)

	screenPos.x = (screenSize.x / 2) - relativePos.x
	screenPos.y = (screenSize.y / 2) - relativePos.y

	return screenPos
}


worldCoordinates :: proc(pos: [2]f32, worldPos: [2]f32, screenSize: [2]f32) -> (mouseCoor: [2]f32) {
	relativePos: [2]f32

	mouseCoor.x = (pos.x - (screenSize.x / 2)) + worldPos.x
	mouseCoor.y = (pos.y - (screenSize.y / 2)) + worldPos.y

	return mouseCoor
}
