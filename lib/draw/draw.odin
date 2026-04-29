package draw

import "base:builtin"
import "core:fmt"
import "core:math"
import "core:c"

import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

import "../utils"
import "../types"
import "../transform"
import "../globals"


crossHair :: proc(mouseCoord : [2] f32, thickness : f32, color : rl.Color, windowSize : [2] f32, camera : rl.Camera2D) {
	horizontalLineP0, horizontalLineP1 : [2] f32 
	verticalLineP0,   verticalLineP1   : [2] f32 

        mouseScreenPos := rl.GetWorldToScreen2D(mouseCoord, camera)

	// horizontalLineP0 = {mouseCoord.x - windowSize.x/2,                  mouseCoord.y}
	// horizontalLineP1 = {mouseCoord.x + windowSize.x/2,                  mouseCoord.y}

	horizontalLineP0 = {0,            mouseScreenPos.y}
	horizontalLineP1 = {windowSize.x, mouseScreenPos.y}

	verticalLineP0   = {mouseScreenPos.x, 0}
	verticalLineP1   = {mouseScreenPos.x, windowSize.y}

        horizontalLineP0 = rl.GetScreenToWorld2D(horizontalLineP0, camera)
        horizontalLineP1 = rl.GetScreenToWorld2D(horizontalLineP1, camera)

        verticalLineP0 = rl.GetScreenToWorld2D(verticalLineP0, camera)
        verticalLineP1 = rl.GetScreenToWorld2D(verticalLineP1, camera)


	rl.DrawLineEx(horizontalLineP0,  horizontalLineP1, thickness/camera.zoom, color)
	rl.DrawLineEx(verticalLineP0,	 verticalLineP1,   thickness/camera.zoom, color)
}

centeredRectangle :: proc (center : [2] f32, size : [2] f32, color : rl.Color) {
        pos : [2] f32 = {center.x - size.x/2, center.y - size.y/2}
        rl.DrawRectangleV(pos, size, color)
}

centeredSquare :: proc (center : [2] f32, length : f32, color : rl.Color) {
        centeredRectangle(center, {length, length}, color)
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

                        rl.DrawLineEx({line0.x, line0.y},  {line0.z, line0.w}, wire.strokeThickness, wire.strokeColor)

                        centeredSquare(line0.xy, wire.strokeThickness, wire.strokeColor)
                        centeredSquare(line0.zw, wire.strokeThickness, wire.strokeColor)
                // If horizontal
                case (p1.y - p0.y) == 0:
                        line0 = {p0.x, p0.y, p1.x, p0.y}

                        rl.DrawLineEx({line0.x, line0.y},  {line0.z, line0.w}, wire.strokeThickness, wire.strokeColor)

                        centeredSquare(line0.xy, wire.strokeThickness, wire.strokeColor)
                        centeredSquare(line0.zw, wire.strokeThickness, wire.strokeColor)
                // If mostly horizontal
                case math.abs(p1.x - p0.x) > math.abs(p1.y - p0.y):
                        line0 = {p0.x, p0.y, p1.x, p0.y}
                        line1 = {p1.x, p0.y, p1.x,   p1.y}

                        rl.DrawLineEx({line0.x, line0.y},  {line0.z, line0.w}, wire.strokeThickness, wire.strokeColor)
                        rl.DrawLineEx({line1.x, line1.y},  {line1.z, line1.w}, wire.strokeThickness, wire.strokeColor)

                        centeredSquare(line0.xy, wire.strokeThickness, wire.strokeColor)
                        centeredSquare(line0.zw, wire.strokeThickness, wire.strokeColor)
                        centeredSquare(line1.zw, wire.strokeThickness, wire.strokeColor)
                // If mostly vertical 
                case math.abs(p1.y - p0.y) > math.abs(p1.x - p0.x):
                        line0 = {p0.x, p0.y, p0.x, p1.y}
                        line1 = {p0.x, p1.y, p1.x,   p1.y}
                        rl.DrawLineEx({line0.x, line0.y},  {line0.z, line0.w}, wire.strokeThickness, wire.strokeColor)
                        rl.DrawLineEx({line1.x, line1.y},  {line1.z, line1.w}, wire.strokeThickness, wire.strokeColor)
                        
                        centeredSquare(line0.xy, wire.strokeThickness, wire.strokeColor)
                        centeredSquare(line0.zw, wire.strokeThickness, wire.strokeColor)
                        centeredSquare(line1.zw, wire.strokeThickness, wire.strokeColor)
                // If diagnal
                case:
                        line0 = {p0.x, p0.y, p1.x, p1.y}

                        rl.DrawLineEx({line0.x, line0.y},  {line0.z, line0.w}, wire.strokeThickness, wire.strokeColor)

                        centeredSquare(line0.xy, wire.strokeThickness*0.5, wire.strokeColor)
                        centeredSquare(line0.zw, wire.strokeThickness*0.5, wire.strokeColor)
                }
        }
}

symbol :: proc(symbolInstance : types.SymbolInstance, camera : rl.Camera2D) {
        internalSymbolPrimitives := make([] types.Primitive, len(symbolInstance.primitives))
        defer delete(internalSymbolPrimitives)
        copy(internalSymbolPrimitives, symbolInstance.primitives)
        internalInstanceCopy := types.SymbolInstance{types.Symbol{symbolInstance.name, internalSymbolPrimitives[:]}, symbolInstance.pos, symbolInstance.rotation, symbolInstance.horizontalFlip, symbolInstance.verticalFlip}

        // Correction for the inverted monitor Y-Axis
        transform.flipVertically(&internalInstanceCopy)

        // Handel Rotation
        switch symbolInstance.rotation  {
        case .East:
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
        if symbolInstance.horizontalFlip {
                transform.flipHorizontally(&internalInstanceCopy)
        }

        pos := internalInstanceCopy.pos

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
                case .Spline:
                case .Triangle:
                        triangle := primitive.triangle

                        p0 := triangle.p0 + pos
                        p1 := triangle.p1 + pos
                        p2 := triangle.p2 + pos

                        lineWidth := triangle.strokeThickness * math.pow(camera.zoom, 2)

                        rlgl.SetLineWidth(lineWidth)

                        rl.DrawTriangle(p0, p1, p2, triangle.fillColor)
                        rl.DrawTriangleLines(p0, p1, p2, triangle.strokeColor)
                case .Rectangle:
                        rectangle := primitive.rectangle
                        
                        rectPos  := rectangle.pos + pos
                        rectSize := rectangle.size

                        rl.DrawRectangleV(rectPos, rectSize, rectangle.fillColor)
                        rl.DrawRectangleLinesEx({rectPos.x, rectPos.y, rectSize.x, rectSize.y}, rectangle.strokeThickness, rectangle.strokeColor)
                case .RoundedRectangle:
                        roundedRectangle         := primitive.roundedRectangle
                        roundness                := roundedRectangle.radius / math.min(roundedRectangle.size.x, roundedRectangle.size.y)
                        roundedRectangleSegments := cast(c.int) (roundedRectangle.radius * 2 * camera.zoom)
                        
                        rectPos  := roundedRectangle.pos + pos
                        rectSize := roundedRectangle.size

                        rl.DrawRectangleRounded({rectPos.x, rectPos.y, rectSize.x,rectSize.y},  roundness, roundedRectangleSegments,roundedRectangle.fillColor)
                        rl.DrawRectangleRoundedLinesEx({rectPos.x, rectPos.y, rectSize.x, rectSize.y}, roundness, roundedRectangleSegments, roundedRectangle.strokeThickness, roundedRectangle.strokeColor)
                case .Circle:
                        lineWidth := primitive.circle.strokeThickness * math.pow(camera.zoom, 2)

                        rlgl.SetLineWidth(lineWidth)

                        rl.DrawCircleV(primitive.circle.center + pos, primitive.circle.radius, primitive.circle.fillColor)
                        rl.DrawCircleLinesV(primitive.circle.center + pos, primitive.circle.radius, primitive.circle.strokeColor)
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

        screenCornerWorld := rl.GetScreenToWorld2D({0, 0}, camera)

        xShift := screenCornerWorld.x - (math.floor(screenCornerWorld.x / gridSize) * gridSize);
        yShift := screenCornerWorld.y - (math.floor(screenCornerWorld.y / gridSize) * gridSize);

        gridShift : [2] f32 = {xShift, yShift}

gridShift = [2]f32{ xShift, yShift };

	switch gridType {
        case .Lines: 
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
                // 1. Calculate the world-space grid index
                // We use floor to ensure that -0.1 becomes -1 (the next grid cell over)
                startX := i64(math.floor(screenCornerWorld.x / gridSize))
                startY := i64(math.floor(screenCornerWorld.y / gridSize))

                for y in 0..<NUM_OF_Y_GRID_LINES {
                        for x in 0..<NUM_OF_X_GRID_LINES {
                                dotScreenPos := rl.Vector2{f32(x), f32(y)} * gridSize + screenCornerWorld - gridShift

                                worldIdxX := startX + i64(x)
                                worldIdxY := startY + i64(y)

                                // 2. Correct Modulo check for Odin
                                // We cast to f32 to use math.mod which handles negatives correctly for grids
                                isMajorX := math.mod(f32(worldIdxX), 5.0) == 0
                                isMajorY := math.mod(f32(worldIdxY), 5.0) == 0
                                isMajor  := isMajorX && isMajorY

                                dotSize := (thickness + (isMajor ? 0.75 : 0.0)) / camera.zoom

                                rl.DrawCircleV(dotScreenPos, dotSize, color)
                        }
                }
        }
}
