package transform

import "core:fmt"
import "core:math"

import "../types"

rotate :: proc (instance : ^ types.SymbolInstance) {
        rotationMatrix : matrix[2, 2] f32 = {
                 0,     1,
                 -1,     0
        }

	for &primitive in instance.primitives {
                switch primitive.type {
                case .Line: 
                        primitive.line.p0 = rotationMatrix * primitive.line.p0 
                        primitive.line.p1 = rotationMatrix * primitive.line.p1 
                case .Spline:
                case .Triangle:
                        primitive.triangle.p0 = rotationMatrix * primitive.triangle.p0
                        primitive.triangle.p1 = rotationMatrix * primitive.triangle.p1
                        primitive.triangle.p2 = rotationMatrix * primitive.triangle.p2
                case .Rectangle:
                        pos  := rotationMatrix * primitive.rectangle.pos
                        size := rotationMatrix * (primitive.rectangle.size + primitive.rectangle.pos)

                        pos, size = {math.min(pos.x, size.x), math.min(pos.y, size.y)}, {math.max(pos.x, size.x), math.max(pos.y, size.y)}

                        primitive.rectangle.pos = pos
                        primitive.rectangle.size = size - pos
                case .RoundedRectangle:
                        pos  := rotationMatrix * primitive.roundedRectangle.pos
                        size := rotationMatrix * (primitive.roundedRectangle.size + primitive.roundedRectangle.pos)

                        pos, size = {math.min(pos.x, size.x), math.min(pos.y, size.y)}, {math.max(pos.x, size.x), math.max(pos.y, size.y)}

                        primitive.roundedRectangle.pos = pos
                        primitive.roundedRectangle.size = size - pos
                case .Circle:
                        primitive.circle.center = rotationMatrix * primitive.circle.center
                case .Sector:
                case .Arc:
                case .Ring:
                case .Polygon:
                }
	}
}

flipHorizontally :: proc (instance : ^ types.SymbolInstance) {
        horizontalFlipMatrix : matrix[2, 2] f32 = {
                -1,  0,
                0,   1
        }

	for &primitive in instance.primitives {
                switch primitive.type {
                case .Line: 
                        primitive.line.p0 = horizontalFlipMatrix * primitive.line.p0 
                        primitive.line.p1 = horizontalFlipMatrix * primitive.line.p1 
                case .Spline:
                case .Triangle:
                        primitive.triangle.p0 = horizontalFlipMatrix * primitive.triangle.p0
                        primitive.triangle.p1 = horizontalFlipMatrix * primitive.triangle.p1
                        primitive.triangle.p2 = horizontalFlipMatrix * primitive.triangle.p2
                case .Rectangle:
                        primitive.rectangle.pos = horizontalFlipMatrix * primitive.rectangle.pos
                        primitive.rectangle.pos.x -= primitive.rectangle.size.x
                case .RoundedRectangle:
                        primitive.roundedRectangle.pos = horizontalFlipMatrix * primitive.roundedRectangle.pos
                        primitive.roundedRectangle.pos.x -= primitive.roundedRectangle.size.x
                case .Circle:
                        primitive.circle.center = horizontalFlipMatrix * primitive.circle.center
                case .Sector:
                case .Arc:
                case .Ring:
                case .Polygon:
                }
	}
}

flipVertically :: proc (instance : ^ types.SymbolInstance) {
        verticalFlipMatrix : matrix[2, 2] f32 = {
                1,  0,
                0,  -1
        }
	for &primitive in instance.primitives {
                switch primitive.type {
                case .Line: 
                        primitive.line.p0 = verticalFlipMatrix * primitive.line.p0 
                        primitive.line.p1 = verticalFlipMatrix * primitive.line.p1 
                case .Spline:
                case .Triangle:
                        primitive.triangle.p0 = verticalFlipMatrix * primitive.triangle.p0
                        primitive.triangle.p1 = verticalFlipMatrix * primitive.triangle.p1
                        primitive.triangle.p2 = verticalFlipMatrix * primitive.triangle.p2
                case .Rectangle:
                        primitive.rectangle.pos = verticalFlipMatrix * primitive.rectangle.pos
                        primitive.rectangle.pos.y -= primitive.rectangle.size.y
                case .RoundedRectangle:
                        primitive.roundedRectangle.pos = verticalFlipMatrix * primitive.roundedRectangle.pos
                        primitive.roundedRectangle.pos.y -= primitive.roundedRectangle.size.y
                case .Circle:
                        primitive.circle.center = verticalFlipMatrix * primitive.circle.center
                case .Sector:
                case .Arc:
                case .Ring:
                case .Polygon:
                }
	}
}
