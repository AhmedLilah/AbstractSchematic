package draw_helper

import "../../types"
import "core:fmt"

rotate :: proc (instance : ^ types.SymbolInstance) {
        rotationMatrix : matrix[2, 2] f32 = {
                 0,     1,
                 -1,     0
        }
	for &line in instance.symbol.lines {
		line.p0 = rotationMatrix * line.p0 
		line.p1 = rotationMatrix * line.p1 
	}
}

flipHorizontally :: proc (instance : ^ types.SymbolInstance) {
        horizontalFlipMatrix : matrix[2, 2] f32 = {
                -1,  0,
                0,   1
        }
        for &line in instance.symbol.lines {
                line.p0 = horizontalFlipMatrix * line.p0 
                line.p1 = horizontalFlipMatrix * line.p1 
        }
}

flipVertically :: proc (instance : ^ types.SymbolInstance) {
        verticalFlipMatrix : matrix[2, 2] f32 = {
                1,  0,
                0,  -1
        }
        for &line in instance.symbol.lines {
                line.p0 = verticalFlipMatrix * line.p0 
                line.p1 = verticalFlipMatrix * line.p1 
        }
}
