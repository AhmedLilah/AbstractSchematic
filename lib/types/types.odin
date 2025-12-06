package types

// Basic Primatives
// --------------------------------------------------
Point :: [2] f32

Line  :: struct {
	p0, p1 : Point,
	thickness : f32
}

Triangle :: struct {
        p0, p1, p2 : Point,
	thickness : f32
}

Rectangle :: struct {
        p0, p1, p2 : Point,
	thickness : f32
}




// Symbols Types
// --------------------------------------------------
Primative :: enum {
        Line,
        Triangle,
        Rectangle, 
        Arc,
        Poly,
        Spline,
}

Primatives :: struct {
        primativeType : Primative,
        primativeData : union {
        },
}

Symbol :: struct {
	name : string,
	lines : [] Line,                        // this should not be only lines because we want other drawing basic types
}

Wire :: struct {
        points    : [] Point,
        thickness : f32,
        pos       : [2] f32
}




// Drawable Symbols Types
// --------------------------------------------------
Rotation :: enum {
	East, 
	West, 
	North,
	South,
}

SymbolInstance :: struct {
	using symbol	: Symbol,
	pos		: Point,
	rotation	: Rotation,
	horizontalFlip	: bool,
	verticalFlip	: bool,
}

DrawableInstance :: union {
        SymbolInstance,
        Wire,
}





GridType :: enum u8 {
	Lines,
	Dots,
}




EditorModes :: enum u8 {
	Normal,
	FileSaving,
	Instantiation,
        Wiring,
}
