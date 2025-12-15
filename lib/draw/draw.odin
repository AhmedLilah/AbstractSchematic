package draw

import "base:builtin"
import "core:fmt"
import "core:math"

import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

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

wire :: proc(wire : types.Wire, camera : rl.Camera2D) {
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

                rl.DrawLineEx({line0.x, line0.y},  {line0.z, line0.w}, wire.strokeThickness, wire.strokeColor)
                rl.DrawLineEx({line1.x, line1.y},  {line1.z, line1.w}, wire.strokeThickness, wire.strokeColor)

                // // dots to fix wire angle discontinuity
                rl.DrawCircleV({line0.x, line0.y}, wire.strokeThickness/2, wire.strokeColor)
                rl.DrawCircleV({line0.z, line0.w}, wire.strokeThickness/2, wire.strokeColor)
                rl.DrawCircleV({line1.x, line1.y}, wire.strokeThickness/2, wire.strokeColor)
                rl.DrawCircleV({line1.z, line1.w}, wire.strokeThickness/2, wire.strokeColor)
        }
}

symbol :: proc(symbolInstance : types.SymbolInstance, camera : rl.Camera2D) {
        internalSymbolPrimitives := make([] types.Primitive, len(symbolInstance.primitives))
        copy(internalSymbolPrimitives, symbolInstance.primitives)
        internalInstanceCopy := types.SymbolInstance{types.Symbol{symbolInstance.name, internalSymbolPrimitives[:]}, symbolInstance.pos, symbolInstance.rotation, symbolInstance.horizontalFlip, symbolInstance.verticalFlip}

        // Correction for the inverted monitor Y-Axis
        draw_helper.flipVertically(&internalInstanceCopy)

        // Handel Rotation
        switch symbolInstance.rotation  {
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
        if symbolInstance.horizontalFlip {
                draw_helper.flipHorizontally(&internalInstanceCopy)
        }

        pos:= internalInstanceCopy.pos

        // Drawing The Primitives
	lastIndex := len(internalInstanceCopy.primitives) - 1
	for primitive in internalInstanceCopy.primitives{
                type := primitive.type
                switch type {
                case .Line: 
                        line := primitive.line

                        p0 := line.p0 + pos
                        p1 := line.p1 + pos
                        rl.DrawLineEx(p0,  p1,  line.strokeThickness, line.strokeColor)

                        // dots to fix wire angle discontinuity
                        rl.DrawCircleV(p0, line.strokeThickness/2, line.strokeColor)
                        rl.DrawCircleV(p1, line.strokeThickness/2, line.strokeColor)
                case .Spline:
                case .Triangle:
                        triangle := primitive.triangle

                        p0 := triangle.p0 + pos
                        p1 := triangle.p1 + pos
                        p2 := triangle.p2 + pos

                        lineWidth := triangle.strokeThickness * math.pow(camera.zoom, 2)

                        fmt.printfln("line width: %v", lineWidth)

                        rlgl.DisableBackfaceCulling()
                        rlgl.SetLineWidth(lineWidth)

                        rl.DrawTriangle(p0, p1, p2, triangle.fillColor)
                        rl.DrawTriangleLines(p0, p1, p2, triangle.strokeColor)
                        
                        // dots to fix wire angle discontinuity
                        rl.DrawCircleV(p0, triangle.strokeThickness/2, triangle.strokeColor)
                        rl.DrawCircleV(p1, triangle.strokeThickness/2, triangle.strokeColor)
                        rl.DrawCircleV(p2, triangle.strokeThickness/2, triangle.strokeColor)
                        
                case .Rectangle:
                case .RoundedRectangle:
                case .Circle:
                case .Sector:
                case .Arc:
                case .Ring:
                case .Polygon:
                }
	}
}

instance :: proc(instance : types.DrawableInstance, camera : rl.Camera2D) {
        switch i in instance {
        case types.SymbolInstance:
                symbol(i, camera)
        case types.Wire:
                wire(i, camera)
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
