package draw

import "base:builtin"
import "core:fmt"
import "core:math"

import rl "vendor:raylib"

import "../utils"
import "../types"
import "../draw/draw_helper"
import "../globals"


crossHair :: proc(mouseCoord : [2] f32, thickness : f32, color : rl.Color, windowSize : [2] f32, camera : rl.Camera2D) {
	horizontalLineP0, horizontalLineP1 : [2] f32 
	verticalLineP0,   verticalLineP1   : [2] f32 

	horizontalLineP0 = {mouseCoord.x - 100, mouseCoord.y}
	horizontalLineP1 = {mouseCoord.x + 100, mouseCoord.y}

	verticalLineP0   = {mouseCoord.x,       mouseCoord.y - 100}
	verticalLineP1   = {mouseCoord.x,       mouseCoord.y + 100}

	rl.DrawLineEx(horizontalLineP0,  horizontalLineP1, thickness/camera.zoom, color)
	rl.DrawLineEx(verticalLineP0,	 verticalLineP1,   thickness/camera.zoom, color)
}

wire :: proc(wire : types.Wire, color : rl.Color, camera : rl.Camera2D) {
        for i in 1..<len(wire.points) {
                p0 := wire.points[i-1] 
                p1 := wire.points[i] 

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

                rl.DrawLineEx({line0.x, line0.y},  {line0.z, line0.w}, wire.thickness, color)
                rl.DrawLineEx({line1.x, line1.y},  {line1.z, line1.w}, wire.thickness, color)

                // // dots to fix wire angle discontinuity
                rl.DrawCircleV({line0.x, line0.y}, wire.thickness/2, color)
                rl.DrawCircleV({line0.z, line0.w}, wire.thickness/2, color)
                rl.DrawCircleV({line1.x, line1.y}, wire.thickness/2, color)
                rl.DrawCircleV({line1.z, line1.w}, wire.thickness/2, color)
        }
}

symbol :: proc(symbol : types.SymbolInstance, color : rl.Color = {0, 0, 0, 255}) {
        internalSymbolLines := make([] types.Line, len(symbol.symbol.lines))
        copy(internalSymbolLines, symbol.lines)
        internalInstanceCopy := types.SymbolInstance{types.Symbol{symbol.symbol.name, internalSymbolLines[:]}, symbol.pos, symbol.rotation, symbol.horizontalFlip, symbol.verticalFlip}

        // Correction for the inverted monitor Y-Axis
        draw_helper.flipVertically(&internalInstanceCopy)

        // Handel Rotation
        switch symbol.rotation  {
        case .East:
        case .North:
                draw_helper.rotate(&internalInstanceCopy)
        case .West:
                draw_helper.rotate(&internalInstanceCopy)
                draw_helper.rotate(&internalInstanceCopy)
        case .South:
                draw_helper.rotate(&internalInstanceCopy)
                draw_helper.rotate(&internalInstanceCopy)
                draw_helper.rotate(&internalInstanceCopy)
        }

        // Vertical Flipping
        if internalInstanceCopy.verticalFlip {
                draw_helper.flipVertically(&internalInstanceCopy)
        }

        // Horizontal Flipping
        if symbol.horizontalFlip {
                draw_helper.flipHorizontally(&internalInstanceCopy)
        }

        // Drawing The Primatives
	lastIndex := len(internalInstanceCopy.lines) - 1
	for line in internalInstanceCopy.lines {
		p0 := line.p0 + internalInstanceCopy.pos
		p1 := line.p1 + internalInstanceCopy.pos
		rl.DrawLineEx(p0,  p1,  line.thickness, color)

                // dots to fix wire angle discontinuity
                rl.DrawCircleV(p0, line.thickness/2, color)
                rl.DrawCircleV(p1, line.thickness/2, color)
	}

        // dots to fix wire angle discontinuity
	rl.DrawCircleV(internalInstanceCopy.lines[lastIndex].p1, internalInstanceCopy.lines[lastIndex].thickness/2, color)
}

instance :: proc(instance : types.DrawableInstance, color : rl.Color = {0, 0, 0, 255}, camera : rl.Camera2D) {
        switch i in instance {
        case types.SymbolInstance:
                symbol(i, color)
        case types.Wire:
                wire(i, color, camera)
        }
} 

grid :: proc (gridSize : f32, gridType : types.GridType, color : rl.Color, windowSize : [2] f32, camera : rl.Camera2D) {
	// Some Constants
	NUM_OF_X_GRID_LINES := (windowSize.x / gridSize) / camera.zoom
	NUM_OF_Y_GRID_LINES := (windowSize.y / gridSize) / camera.zoom
	thickness :: globals.DEFAULT_GRID_ELEMENT_THICKNESS

	switch gridType {
        case .Lines: 
		screenCornerWorld := rl.GetScreenToWorld2D({0, 0}, camera)
		gridShift : [2] f32 = {cast(f32) ((cast(i32) screenCornerWorld.x) % (cast(i32) gridSize)), cast(f32) ((cast(i32) screenCornerWorld.y) % (cast(i32) gridSize))}
		// // Drawing horizontal Lines
		for y in 0..<NUM_OF_Y_GRID_LINES {
			worldYPos := cast(f32) y * gridSize
			p0ScreenPos := rl.Vector2{0                                      , worldYPos} + screenCornerWorld - gridShift
			p1ScreenPos := rl.Vector2{(windowSize.x / camera.zoom) + gridSize, worldYPos} + screenCornerWorld - gridShift
			lineThickness := (thickness + 0.5 * (((cast(i64) y % 5) == 0) ? 1 : 0) ) / camera.zoom
			rl.DrawLineEx(p0ScreenPos, p1ScreenPos, lineThickness, color)
		}

		// Drawing Vertical Lines
		for x in 0..<NUM_OF_X_GRID_LINES {
			worldXPos := cast(f32) x * gridSize
			p0ScreenPos := rl.Vector2{worldXPos,                                       0} + screenCornerWorld - gridShift
			p1ScreenPos := rl.Vector2{worldXPos, (windowSize.y / camera.zoom) + gridSize} + screenCornerWorld - gridShift
			lineThickness := (thickness + 0.5 * (((cast(i64) x % 5) == 0) ? 1 : 0) ) / camera.zoom
			rl.DrawLineEx(p0ScreenPos, p1ScreenPos, lineThickness, color)
		}
        case .Dots:
		// Drawing a dotted grid
		for y in 0..<NUM_OF_Y_GRID_LINES {
			for x in 0..<NUM_OF_X_GRID_LINES {
				screenCornerWorld := rl.GetScreenToWorld2D({0, 0}, camera)
				gridShift : [2] f32 = {cast(f32) ((cast(i32) screenCornerWorld.x) % (cast(i32) gridSize)), cast(f32) ((cast(i32) screenCornerWorld.y) % (cast(i32) gridSize))}
				dotScreenPos := rl.Vector2{x, y} * gridSize + screenCornerWorld - gridShift
				dotSize := (thickness + 0.5 * (((cast(i64) x % 5) == 0 && (cast(i64) y % 5) == 0) ? 1 : 0) ) / camera.zoom
				rl.DrawCircleV(dotScreenPos, dotSize, color)
			}
		}
	}
}
