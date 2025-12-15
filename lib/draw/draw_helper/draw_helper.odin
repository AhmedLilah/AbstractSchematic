package draw_helper

import "../../types"
import "core:fmt"

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
