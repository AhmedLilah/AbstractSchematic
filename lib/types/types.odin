package types

import rl "vendor:raylib"


// Basic Types
Point :: [2] f32

// Basic Primitives
// --------------------------------------------------

FillType :: enum {
        None,
        Solid,
        Gradient,
}

StrokeData :: struct {
        strokeColor     : rl.Color,
        strokeThickness : f32
}

FillData :: struct {
        fillType     : FillType,
        fillColor    : rl.Color,
}

FillAndStroke :: struct {
        using fill   : FillData,
        using stroke : StrokeData,
}

Line  :: struct {
	p0, p1       : Point,
        using stroke : StrokeData,
}

SplineType :: enum {
        Linear,
        Basis,
        CatmullRom,
        BezierQuadratic,
        BezierCubic,
}

Spline :: struct {
        splineType   : SplineType,
        points       : [4] Point,
        using stroke : StrokeData,
}

Triangle :: struct {
        p0, p1, p2          : Point,
        using strokeAndFill : FillAndStroke,
}

Rectangle :: struct {
        pos, size           : Point,
        using strokeAndFill : FillAndStroke,
}

RoundedRectangle :: struct {
        pos, size           : Point,
        radius              : f32,
        using strokeAndFill : FillAndStroke,
}

Circle :: struct {
        center              : Point,
        radius              : f32,
        using strokeAndFill : FillAndStroke,
}

Sector :: struct {
        center       : Point,
        radius       : f32,
        startAngle   : f32,
        endAngle     : f32,
        using stroke : StrokeData,
}

Arc :: struct {
        center       : Point,
        radius       : f32,
        startAngle   : f32,
        endAngle     : f32,
        using stroke : StrokeData,
}

Ring :: struct {
        center              : Point,
        innerRadius         : f32,
        outerRadius         : f32,
        startAngle          : f32,
        endAngle            : f32,
        using strokeAndFill : FillAndStroke,
}

Polygon :: struct {
        center              : Point,
        numberOfSides       : f32,
        radius              : f32,
        rotation            : f32,
        using strokeAndFill : FillAndStroke,
}


// Symbols Types
// --------------------------------------------------
PrimitiveType :: enum {
        Line,
        Spline,
        Triangle,
        Rectangle, 
        RoundedRectangle,
        Circle,
        Sector,
        Arc,
        Ring,
        Polygon,
}

Primitive :: struct {
        type : PrimitiveType,
        using data : struct #raw_union {
                line             : Line,
                spline           : Spline,
                triangle         : Triangle,
                rectangle        : Rectangle,
                roundedRectangle : RoundedRectangle,
                circle           : Circle,
                sector           : Sector,
                arc              : Arc,
                ring             : Ring,
                polygon          : Polygon,
        }
}

Symbol :: struct {
	name       : string,
	primitives : [] Primitive,
}

Wire :: struct {
        points       : [] Point,
        using stroke : StrokeData,
        pos          : [2] f32
        // @TODO: Add a net/wire name filed here.
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
