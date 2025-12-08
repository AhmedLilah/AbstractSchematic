package main

// Importing required packages ----------------------------------------------------------------------------------------------------
import "core:fmt"
import "core:math"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"

import rl "vendor:raylib"

import "lib/utils"
import "lib/draw"
import "lib/types"
import "lib/globals"



main :: proc() {
        // Global State
        windowSize			:= globals.INITIAL_WINDOW_SIZE		// Initail Window Size
        showGrid                        := true                                 // Boolean that controls the grid visibility
        showFineGrid                    := false                                // Boolean that controls the fine grid visibility
        deviceModels                    :  [dynamic] types.Symbol               // All device models
        instances			:  [dynamic] types.DrawableInstance	// Drawn Symbols Container
        wirePointsBuffer                :  [dynamic] types.Point                // Temporary wire points buffer
        wireThickness                   :  f32 = globals.DEFAULT_WIRE_THICKNESS // 
        modelToInstanciate		:  types.DrawableInstance		// The model of the object chosed to be instanciated from 
        editorMode			:  types.EditorModes			// Different modes for the editors
        newSymbolName			:  strings.Builder			// Temporay holder to accept user input.
        mouseOldPos                     := rl.GetMousePosition()                // 
        mouseOldCoord                   :  [2] f32                              // 
        previousLeftClickIsDown         := false                                // 
        modelIndex                      := 0                                    //

        // Deallocating the memory
        defer {
                for &deviceModel in deviceModels {
                        delete(deviceModel.primatives)
                }
                delete(deviceModels)
        }

        defer {
                delete(instances)
        }

        delete(wirePointsBuffer)

        defer strings.builder_destroy(&newSymbolName)
        strings.builder_grow(&newSymbolName, 100)


        // Raylib Initial Setup
        // ----------------------------------------------------------------------------------------------------
        // Setting Raylib Flags
        rl.SetConfigFlags({ rl.ConfigFlag.VSYNC_HINT,
                // rl.ConfigFlag.FULLSCREEN_MODE,
                rl.ConfigFlag.WINDOW_RESIZABLE,
                // rl.ConfigFlag.WINDOW_UNDECORATED,
                // rl.ConfigFlag.WINDOW_HIDDEN,
                // rl.ConfigFlag.WINDOW_MINIMIZED,
                // rl.ConfigFlag.WINDOW_MAXIMIZED,
                // rl.ConfigFlag.WINDOW_UNFOCUSED,
                // rl.ConfigFlag.WINDOW_TOPMOST,
                // rl.ConfigFlag.WINDOW_ALWAYS_RUN,
                // rl.ConfigFlag.WINDOW_TRANSPARENT,
                // rl.ConfigFlag.WINDOW_HIGHDPI,
                // rl.ConfigFlag.WINDOW_MOUSE_PASSTHROUGH,
                // rl.ConfigFlag.BORDERLESS_WINDOWED_MODE,
                rl.ConfigFlag.MSAA_4X_HINT,
                // rl.ConfigFlag.INTERLACED_HINT,
        })

        // Window Setup
        rl.InitWindow(cast(i32) globals.INITIAL_WINDOW_SIZE.x, cast(i32) globals.INITIAL_WINDOW_SIZE.y, "Abstract Schmematic Editor")
        defer rl.CloseWindow()
        rl.SetTargetFPS(globals.TARGET_FPS)
        rl.SetExitKey(.KEY_NULL)

        // Cursor Setup
        rl.HideCursor()

        // Cmaera Setup
        camera : rl.Camera2D
        camera.target = {0, 0}
        camera.offset = {0, 0}
        camera.rotation = 0.0
        camera.zoom = 1.0

        // Font Setup
        font := rl.LoadFont("assets/fonts/Roboto-VariableFont_wdth,wght.ttf")
        defer if rl.IsFontValid(font) {
                rl.UnloadFont(font)
        } 
        if !rl.IsFontValid(font)  {
                font = rl.GetFontDefault()
        }

        // // Loading Shaders
        // antiAliasingShader := rl.LoadShader(nil, "shaders/frag/anti_aliasing.frag")
        // if rl.IsShaderValid(antiAliasingShader) {
        // 	defer rl.UnloadShader(antiAliasingShader)
        // }

        // Reading the library files
        // ----------------------------------------------------------------------------------------------------
        deviceModels = utils.readLibraryModelFiles("assets/symbols/basic")


        // Main Loop
        // ----------------------------------------------------------------------------------------------------
        for !rl.WindowShouldClose() {

                // Handle Full Screen
                if rl.IsKeyPressed(.F11) {
                        rl.ToggleBorderlessWindowed()
                }

                // Window size
                if rl.IsWindowResized(){
                        windowSize = {cast(f32) rl.GetScreenWidth(), cast(f32) rl.GetScreenHeight()}
                }

                // Calculate Mouse Pos
                mousePos := rl.GetMousePosition()
                mouseCoord := rl.GetScreenToWorld2D(mousePos, camera)
                mouseGridCoord : [2]f32 =  {0, 0}
                if (rl.IsKeyDown(.LEFT_ALT) || rl.IsKeyDown(.RIGHT_ALT)) && rl.IsKeyPressed(.G) {
                        showFineGrid = !showFineGrid
                } else if rl.IsKeyPressed(.G) {
                        showGrid = !showGrid
                }
                if showFineGrid {
                        mouseGridCoord = {utils.round(mouseCoord.x, globals.DEFAULT_GRID_SIZE/5), utils.round(mouseCoord.y, globals.DEFAULT_GRID_SIZE/5)}
                } else {
                        mouseGridCoord = {utils.round(mouseCoord.x, globals.DEFAULT_GRID_SIZE), utils.round(mouseCoord.y, globals.DEFAULT_GRID_SIZE)}
                } 

                switch editorMode {
                case .Normal:
                        // Handle keyboard Input
                        if rl.IsKeyPressed(.F) {
                                camera.zoom = 1
                        } else if rl.IsKeyPressed(.O) {
                                camera.target -= camera.target
                                camera.offset -= camera.offset 
                        } else if rl.IsKeyPressed(.I) {
                                devMod := deviceModels[modelIndex]
                                modelToInstanciate = types.SymbolInstance{devMod, mouseCoord, .East, false, false}
                                editorMode = .Instantiation
                        } else if rl.IsKeyPressed(.W) {
                                editorMode = .Wiring
                        } else if rl.IsKeyDown(.SPACE) {
                                if rl.IsMouseButtonDown(.LEFT) {
                                        previousLeftClickIsDown = true
                                        delta := rl.GetMouseDelta()
                                        delta = delta * (-1.0/camera.zoom)
                                        camera.target = camera.target + delta

                                        mouseWorldPos := rl.GetScreenToWorld2D(mousePos, camera)
                                        camera.offset = mousePos
                                        camera.target = mouseWorldPos
                                }
                        } else if (rl.IsKeyDown(.LEFT_CONTROL) || rl.IsKeyDown(.LEFT_CONTROL)) && rl.IsKeyPressed(.S) {
                                editorMode = .FileSaving
                        } else if (rl.IsKeyDown(.LEFT_CONTROL) || rl.IsKeyDown(.LEFT_CONTROL)) && rl.IsKeyPressed(.Z) {
                                if length:= len(instances); length > 0 {
                                        resize(&instances, length-1)
                                }
                        }

                        // Zoom
                        wheel := rl.GetMouseWheelMove()
                        if wheel != 0 {
                                mouseWorldPos := rl.GetScreenToWorld2D(mousePos, camera)
                                camera.offset = mousePos
                                camera.target = mouseWorldPos

                                // Zoom increment
                                // Uses log scaling to provide consistent zoom speed
                                scale := 0.2 * wheel
                                camera.zoom = rl.Clamp(camera.zoom + (math.exp(math.log2(camera.zoom)) * scale), globals.DEFAULT_MIN_ZOOM, globals.DEFAULT_MAX_ZOOM)
                        }
                case .Instantiation:
                        // Handle keyboard Input
                        if rl.IsKeyPressed(.ESCAPE) {
                                editorMode = .Normal 
                                modelIndex = 0
                        } else if rl.IsKeyPressed(.F) {
                                camera.zoom = 1
                        } else if rl.IsKeyPressed(.O) {
                                camera.target -= camera.target
                                camera.offset -= camera.offset 
                        } else if rl.IsKeyPressed(.TAB) {
                                devMod := deviceModels[modelIndex%len(deviceModels)]
                                modelToInstanciate = types.SymbolInstance{devMod, mouseCoord, .East, false, false}
                                modelIndex += 1
                        } else if rl.IsKeyPressed(.R) {
                                symbolInstance := &modelToInstanciate.(types.SymbolInstance)
                                switch symbolInstance.rotation {
                                case .East:
                                        symbolInstance.rotation = .North
                                case .North:
                                        symbolInstance.rotation = .West
                                case .West:
                                        symbolInstance.rotation = .South
                                case .South:
                                        symbolInstance.rotation = .East
                                }
                        } else if rl.IsKeyPressed(.V) {
                                symbolInstance := &modelToInstanciate.(types.SymbolInstance)
                                symbolInstance.verticalFlip = !modelToInstanciate.(types.SymbolInstance).verticalFlip
                        } else if rl.IsKeyPressed(.H) {
                                symbolInstance := &modelToInstanciate.(types.SymbolInstance)
                                symbolInstance.horizontalFlip = !modelToInstanciate.(types.SymbolInstance).horizontalFlip
                        } else if rl.IsKeyDown(.SPACE) {
                                if rl.IsMouseButtonDown(.LEFT) {
                                        previousLeftClickIsDown = true
                                        delta := rl.GetMouseDelta()
                                        delta = delta * (-1.0/camera.zoom)
                                        camera.target = camera.target + delta

                                        mouseWorldPos := rl.GetScreenToWorld2D(mousePos, camera)
                                        camera.offset = mousePos
                                        camera.target = mouseWorldPos
                                }
                        } else if (rl.IsKeyDown(.LEFT_CONTROL) || rl.IsKeyPressed(.RIGHT_CONTROL)) && rl.IsKeyDown(.S) {
                                editorMode = .FileSaving
                        }

                        // Handle Mouse Input
                        if rl.IsMouseButtonPressed(.LEFT) {
                                append(&instances, modelToInstanciate.(types.SymbolInstance))
                        }

                        // Zoom
                        wheel := rl.GetMouseWheelMove()
                        if wheel != 0 {
                                mouseWorldPos := rl.GetScreenToWorld2D(mousePos, camera)
                                camera.offset = mousePos
                                camera.target = mouseWorldPos

                                // Zoom increment
                                // Uses log scaling to provide consistent zoom speed
                                scale := 0.2 * wheel
                                camera.zoom = rl.Clamp(camera.zoom + (math.exp(math.log2(camera.zoom)) * scale), globals.DEFAULT_MIN_ZOOM, globals.DEFAULT_MAX_ZOOM)
                        }
                case .Wiring:
                        // Handle keyboard input
                        if rl.IsKeyPressed(.ESCAPE) {
                                if len(wirePointsBuffer) > 1 {
                                        wire : types.Wire
                                        wire.pos = wirePointsBuffer[0]
                                        if size := len(wirePointsBuffer); size % 2 == 0 {
                                                wire.points = make([] types.Point, len(wirePointsBuffer))
                                                wire.stroke = {rl.BLACK, wireThickness}
                                                copy(wire.points, wirePointsBuffer[:])
                                                append(&instances, wire)
                                        } else {
                                                resize(&wirePointsBuffer, size-1)
                                                wire.points = make([] types.Point, len(wirePointsBuffer))
                                                wire.stroke = {rl.BLACK, wireThickness}
                                                copy(wire.points, wirePointsBuffer[:])
                                                append(&instances, wire)
                                        }
                                }
                                resize(&wirePointsBuffer, 0)
                                editorMode = .Normal 
                                wireThickness = globals.DEFAULT_WIRE_THICKNESS
                        } else if (rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT)) && rl.IsKeyPressed(.EQUAL) {
                                wireThickness += 1
                        } else if (rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT)) && rl.IsKeyPressed(.MINUS) {
                                if wireThickness > 0 {
                                        wireThickness -= 1
                                }
                        }

                        // Handle mouse input
                        if rl.IsMouseButtonPressed(.LEFT) {
                                append(&wirePointsBuffer, mouseGridCoord)
                        }
                case .FileSaving: 
                        if rl.IsKeyPressed(.ESCAPE) {
                                editorMode = .Normal 
                                strings.builder_reset(&newSymbolName)
                        } else if (rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.KP_ENTER)) && (strings.builder_len(newSymbolName) > 0) {
                                editorMode = .Normal 
                                utils.saveSymbolToFile(transmute(string)newSymbolName.buf[:], instances[:])
                                strings.builder_reset(&newSymbolName)
                                resize(&deviceModels, 0)
                                deviceModels = utils.readLibraryModelFiles("assets/symbols/basic")
                                editorMode = .Normal
                        } else if rl.IsKeyPressed(.BACKSPACE) {
                                if len := strings.builder_len(newSymbolName); len > 0 {
                                        resize(&newSymbolName.buf, len-1)
                                }
                                for rl.IsKeyPressedRepeat(.BACKSPACE) {
                                        if len := strings.builder_len(newSymbolName); len > 0 {
                                                resize(&newSymbolName.buf, len-1)
                                        }
                                }
                        } else {
                                currentCharPressed := rl.GetCharPressed()
                                for currentCharPressed != 0 {	
                                        strings.write_rune(&newSymbolName, currentCharPressed)
                                        currentCharPressed = rl.GetCharPressed()
                                } 
                        }
                } 


                // Starting the drawing mode
                // ----------------------------------------------------------------------------------------------------
                rl.BeginDrawing()


                // Clearing  the background
                rl.ClearBackground(rl.WHITE)


                // Starting the drawing mode
                // ----------------------------------------------------------------------------------------------------
                rl.BeginMode2D(camera)


                // Hadeling adaptive grid sizing
                gridSize : f32
                if showGrid {
                        if 0.2 <= camera.zoom && camera.zoom < 0.75{
                                gridSize = globals.DEFAULT_GRID_SIZE * globals.DEFAULT_GRID_SCALING_FACTOR
                        } else if 0.75 <= camera.zoom && camera.zoom < 4 {
                                gridSize = globals.DEFAULT_GRID_SIZE
                        } else if  4 <= camera.zoom  && camera.zoom <= 5 {
                                gridSize = globals.DEFAULT_GRID_SIZE / globals.DEFAULT_GRID_SCALING_FACTOR
                        }

                        if showFineGrid {
                                // Drawing the grid
                                draw.grid(gridSize/globals.DEFAULT_FINE_GRID_FACTOR, .Dots, globals.DEFAULT_GRID_COLOR, windowSize, camera)
                        } else {
                                // Drawing the grid
                                draw.grid(gridSize, .Dots, globals.DEFAULT_GRID_COLOR, windowSize, camera)
                        }
                }

                // Draw Symbols
                for &instance in instances {
                        draw.instance(instance, camera)
                }

                // show the file name to be saved
                switch editorMode {
                case .Normal:
                        draw.crossHair(mouseGridCoord, globals.DEFAULT_CROSSHAIR_THICKNESS, globals.DEFAULT_CROSSHAIR_COLOR, windowSize, camera)
                case .Instantiation:
                        symbolInstance := &modelToInstanciate.(types.SymbolInstance)
                        symbolInstance.pos = mouseGridCoord
                        draw.instance(modelToInstanciate.(types.SymbolInstance), camera)
                        draw.crossHair(mouseGridCoord, globals.DEFAULT_CROSSHAIR_THICKNESS, globals.DEFAULT_CROSSHAIR_COLOR, windowSize, camera)
                case .Wiring:
                        append(&wirePointsBuffer, mouseGridCoord)
                        draw.wire(types.Wire{wirePointsBuffer[:], {rl.BLACK, wireThickness}, mouseGridCoord}, camera)
                        resize(&wirePointsBuffer, len(wirePointsBuffer)-1)
                        draw.crossHair(mouseGridCoord, globals.DEFAULT_CROSSHAIR_THICKNESS, globals.DEFAULT_CROSSHAIR_COLOR, windowSize, camera)
                case .FileSaving:
                        topRectStartPos := rl.GetScreenToWorld2D({0, 0}, camera)
                        topTextStartPos := rl.GetScreenToWorld2D({globals.DEFAULT_TEXT_PADDING, globals.DEFAULT_TEXT_PADDING}, camera)
                        rl.DrawRectangleV(topRectStartPos, {windowSize.x, globals.DEFAULT_TEXT_SIZE + 2 * globals.DEFAULT_TEXT_PADDING}/camera.zoom, rl.RAYWHITE)
                        rl.DrawLineEx({topRectStartPos.x,  topRectStartPos.y + (globals.DEFAULT_TEXT_SIZE + 2 * globals.DEFAULT_TEXT_PADDING)/camera.zoom}, 
                                {topRectStartPos.x + (windowSize.x/camera.zoom), topRectStartPos.y + ((globals.DEFAULT_TEXT_SIZE + 2 * globals.DEFAULT_TEXT_PADDING)/camera.zoom)}, 
                                globals.DEFAULT_LINE_THICKNESS/camera.zoom, rl.BLACK)
                        rl.DrawTextEx(font, strings.clone_to_cstring(transmute(string)newSymbolName.buf[:]), topTextStartPos, auto_cast (globals.DEFAULT_TEXT_SIZE/camera.zoom), 0, rl.BLACK)
                }	


                bottomRectStartPos := rl.GetScreenToWorld2D({0, windowSize.y - globals.DEFAULT_TEXT_SIZE - 2 * globals.DEFAULT_TEXT_PADDING}, camera)
                bottomTextStartPos := rl.GetScreenToWorld2D({globals.DEFAULT_TEXT_PADDING, windowSize.y - globals.DEFAULT_TEXT_SIZE - globals.DEFAULT_TEXT_PADDING}, camera)
                rl.DrawRectangleV(bottomRectStartPos, {windowSize.x, 36}/camera.zoom, rl.RAYWHITE)
                rl.DrawLineEx(bottomRectStartPos, {(bottomRectStartPos.x + windowSize.x/camera.zoom), bottomRectStartPos.y}, globals.DEFAULT_LINE_THICKNESS/camera.zoom, rl.BLACK)
                rl.DrawTextEx(font, rl.TextFormat("X: %v, Y: %v, \tZoom: %v%%, \tGrid Size: %v, \tFine Grid: %v, \tWire Thickness: %v", 
                                                  mouseGridCoord.x, mouseGridCoord.y, camera.zoom * 100, gridSize, showFineGrid, wireThickness), 
                                                  bottomTextStartPos, auto_cast (globals.DEFAULT_TEXT_SIZE/camera.zoom), 0, rl.BLACK)


                // // Starting Shader Mode
                // // ----------------------------------------------------------------------------------------------------
                // rl.BeginShaderMode(antiAliasingShader)
                //
                //
                // // Ending Shader Mode
                // // ----------------------------------------------------------------------------------------------------
                // rl.EndShaderMode()


                // Starting the drawing mode
                // ----------------------------------------------------------------------------------------------------
                rl.EndMode2D()


                // Ending drawing mode
                // ----------------------------------------------------------------------------------------------------
                rl.EndDrawing()


                free_all()
        }
}
