package draw_helper

import "../../types"
import "core:fmt"

rotate :: proc (instance : ^ types.SymbolInstance) {
        rotationMatrix : matrix[2, 2] f32 = {
                 0,     1,
                 -1,     0
        }

	for &primative in instance.primatives {
                switch primative.type {
                case .Line: 
                        primative.data.line.p0 = rotationMatrix * primative.data.line.p0 
                        primative.data.line.p1 = rotationMatrix * primative.data.line.p1 
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

	for &primative in instance.primatives {
                switch primative.type {
                case .Line: 
                        primative.data.line.p0 = horizontalFlipMatrix * primative.data.line.p0 
                        primative.data.line.p1 = horizontalFlipMatrix * primative.data.line.p1 
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
	for &primative in instance.primatives {
                switch primative.type {
                case .Line: 
                        primative.data.line.p0 = verticalFlipMatrix * primative.data.line.p0 
                        primative.data.line.p1 = verticalFlipMatrix * primative.data.line.p1 
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
