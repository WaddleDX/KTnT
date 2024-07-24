-------------------------------------
-- Koro Koro Kirby - lua for TAS   --
--                            v2.0 --
-------------------------------------
-- Author:
--      WaddleDX
-- Works with the following emulators:
--      BizHawk 2.9.1
--      BizHawk 2.9
--      BizHawk 2.8
-- Works with the following cores:
--      GBHawk

-- Option
local POINT_RAD = 2             -- Radius of tilt coordinate point (px)
local POINT_RAD_PREVIOUS = 1    -- Radius of tilt coordinate point (px/previous frame)
local TILT_MOVE_GRID = 10       -- Grid spacing for key-in tilt input
local EDGE_MOVE_LIMIT = 90      -- Limit of tilt input by HotKey operation
local ENABLE_TILT_ARROW = true  -- Display the TILT Arrow GUI
local ENABLE_CLICK = false      -- Allow mouse input
local ENABLE_JOYPAD = true      -- Allow controller input

-- HotKey
local TILT_MOVE_UP = "Up"
local TILT_MOVE_DOWN = "Down"
local TILT_MOVE_LEFT = "Left"
local TILT_MOVE_RIGHT = "Right"
-- local TILT_MOVE_UPLEFT = ""
-- local TILT_MOVE_UPRIGHT = ""
-- local TILT_MOVE_DOWNLEFT = ""
-- local TILT_MOVE_DOWNRIGHT = ""
local TILT_MOVE_CENTER = "Home"
local TILT_MOVE_PREVIOUS = "End"

local TILT_UP_ONE = "Ctrl+Up"
local TILT_DOWN_ONE = "Ctrl+Down"
local TILT_LEFT_ONE = "Ctrl+Left"
local TILT_RIGHT_ONE = "Ctrl+Right"

local TILT_UP_LAST = "Ctrl+Shift+Up"
local TILT_DOWN_LAST = "Ctrl+Shift+Down"
local TILT_LEFT_LAST = "Ctrl+Shift+Left"
local TILT_RIGHT_LAST = "Ctrl+Shift+Right"

local TILT_POP_TOGGLE = "PageDown"

-- Profile
local SCRIPT_NAME = "KTnT_TAS" -- Script Name

-- Set input key name (Depends on the core)
local INPUT_TILTX = "P1 Tilt X" -- Horizontal axis tilt
local INPUT_TILTY = "P1 Tilt Y" -- Vertical axis tilt

-- Setting constants
local INFO_OFS_X = 216  -- X-position of info area (px)
local INFO_OFS_Y = 12   -- Y-position of info area (px)
local INFO_ROW_HEIGHT = 16  -- Row height of info area

local EXPADDING_TOP = 64    -- Outer frame_top (px)
local EXPADDING_BOTTOM = 64 -- Outer frame_bottom (px)
local EXPADDING_LEFT = 32   -- Outer frame_left (px)
local EXPADDING_RIGHT = 220 -- Outer frame_right (px)

local TILT_INPUT_PADDING = 20   -- Outer frame width of the tilt input GUI (px)
local AXIS_SIZE = 90    -- Size of tilt input GUI (px from center)

local TILT_ARROW_SCALE = 0.38      -- Tilt arrow scale
local TILT_ARROW_MAX = 100         -- Maximum length of Tilt arrow (px)

local POP_RANGE = 18 -- Tilt differential for flip-up toggle
local NON_POP_RANGE = 17    -- Maximum tilt difference to prevent bounce

local controllerEnable = false    -- For Controller input recognition

-- hot-key flag
local keyMoveUp = {key = TILT_MOVE_UP, current = false, previous = false, pressed = false}
local keyMoveDown = {key = TILT_MOVE_DOWN, current = false, previous = false, pressed = false}
local keyMoveLeft = {key = TILT_MOVE_LEFT, current = false, previous = false, pressed = false}
local keyMoveRight = {key = TILT_MOVE_RIGHT, current = false, previous = false, pressed = false}
-- local keyMoveUpLeft = {key = TILT_MOVE_UPLEFT, current = false, previous = false, pressed = false}
-- local keyMoveUpRight = {key = TILT_MOVE_UPRIGHT, current = false, previous = false, pressed = false}
-- local keyMoveDownLeft = {key = TILT_MOVE_DOWNLEFT, current = false, previous = false, pressed = false}
-- local keyMoveDownRight = {key = TILT_MOVE_DOWNRIGHT, current = false, previous = false, pressed = false}
local keyMoveCenter = {key = TILT_MOVE_CENTER, current = false, previous = false, pressed = false}
local keyMovePrevious = {key = TILT_MOVE_PREVIOUS, current = false, previous = false, pressed = false}

local keyUpOne = {key = TILT_UP_ONE, current = false, previous = false}
local keyDownOne = {key = TILT_DOWN_ONE, current = false, previous = false}
local keyLeftOne = {key = TILT_LEFT_ONE, current = false, previous = false}
local keyRightOne = {key = TILT_RIGHT_ONE, current = false, previous = false}

local keyUpLast = {key = TILT_UP_LAST, current = false, previous = false}
local keyDownLast = {key = TILT_DOWN_LAST, current = false, previous = false}
local keyLeftLast = {key = TILT_LEFT_LAST, current = false, previous = false}
local keyRightLast = {key = TILT_RIGHT_LAST, current = false, previous = false}

local keyPopToggle = {key = TILT_POP_TOGGLE, current = false, previous = false}

-- Input Variables
local tiltX = 0             -- X-axis Tilt input (pop toggle included)
local tiltY = 0             -- Y-axis Tilt input (pop toggle included)
local tiltX_ofs = 0         -- X-axis Tilt input
local tiltY_ofs = 0         -- Y-axis Tilt input
local tiltX_previous = 0    -- X-axis Tilt input (previous frame)
local tiltY_previous = 0    -- Y-axis Tilt input (previous frame)
local tiltOutX = 0          -- X-axis Tilt output
local tiltOutY = 0          -- Y-axis Tilt output

-- Tilt to save with state save
local saveXinput = {key = SCRIPT_NAME .. "_Xinput", value = 0} -- X-axis Tilt input to save
local saveYinput = {key = SCRIPT_NAME .. "_Yinput", value = 0} -- Y-axis Tilt input to save

-- Set window size to x2 or larger (as text will be hidden)
if client.getwindowsize() <= 1 then
    client.setwindowsize(2)
end

-- Memory Domain Settings
memory.usememorydomain("System Bus")

--------------
-- Function --
--------------

-- Check if the input of the previous frame can be acquired.
function checkPreviousFrame()
    local check = false
    if movie.mode() == "PLAY" or movie.mode() == "RECORD" then
        if emu.framecount() >= 1 then
            check = true
        end
    end
    return check
end

-- Calculate to grid coordinates
-- * tilt :  TILT
-- * isAdd : Check if it has been added in the forward direction
function adjustGridCalc(tilt, isAdd)
    local adjustedTilt
    local div = tilt / TILT_MOVE_GRID
    local multi = 0
    -- For positive direction, isAdd is true; for negative direction, isAdd is false.
    if isAdd then
        multi = math.floor(div + 1)
    else
        multi = math.ceil(div - 1)
    end
    adjustedTilt = multi * TILT_MOVE_GRID
    return adjustedTilt
end

-- Convert output Tilt
-- * tiltOut :  Output Tilt
-- * tiltFlat : Output Tilt at horizontal
function tiltConvertor(tiltOut, tiltFlat)
    local convTilt = math.floor((tiltOut - tiltFlat) / 16)
    return convTilt
end

-- Correct Tilt coordinates from -90 to 90
-- * tilt : Tilt
function clampTilt(tilt)
    if tilt < -90 then
        tilt = -90
    elseif tilt > 90 then
        tilt = 90
    end
    return tilt
end

-- Corrects the absolute value of the Tilt coordinate below the upper tilt limit
-- * tilt : Tilt
function clampTiltLimit(tilt)
    if tilt < -EDGE_MOVE_LIMIT then
        tilt = -EDGE_MOVE_LIMIT
    elseif tilt > EDGE_MOVE_LIMIT then
        tilt = EDGE_MOVE_LIMIT
    end
    return tilt
end

-- Long press determination of shortcut keys
-- * keyTable :     key input table
-- * inputTable :   Input table obtained from emulator
function isKeyPressed(keyTable, inputTable)
    local input = false
    if inputTable[keyTable["key"]] then
        input = true
    end
    keyTable["current"] = input
    keyTable["pressed"] = keyTable["current"]
    if keyTable["previous"] then
        keyTable["pressed"] = false
    end
    keyTable["previous"] = keyTable["current"]
    return input
end

-- Detects controller tilt input
-- * getInput : TILT value received from controller
function controllerDetecter(getInput)
    local controllerTilted = false
    if getInput["P1 Tilt X"] ~= 0 or getInput["P1 Tilt Y"] ~= 0 then
        controllerTilted = true
    end
    return controllerTilted
end

-- Change Tilt with hotkeys

-- Move to top edge (by HotKey)
-- * tiltY_ofs :        Y-axis Tilt input
-- * tiltY_previous :   Y-axis Tilt input (previous frame)
function tiltMoveTop(tiltY_ofs, tiltY_previous)
    if movie.isloaded() then
        if tiltY_ofs > tiltY_previous + NON_POP_RANGE then
            tiltY_ofs = tiltY_previous + NON_POP_RANGE
        elseif tiltY_ofs > tiltY_previous - NON_POP_RANGE then
            tiltY_ofs = tiltY_previous - NON_POP_RANGE
        else
            tiltY_ofs = -EDGE_MOVE_LIMIT
        end
    else
        tiltY_ofs = -EDGE_MOVE_LIMIT
    end
    if tiltY_ofs < -EDGE_MOVE_LIMIT then
        tiltY_ofs = -EDGE_MOVE_LIMIT
    end
    return tiltY_ofs
end

-- Move to left end  (by HotKey)
-- * tiltX_ofs :    X-axis Tilt input
function tiltMoveLeftEnd(tiltX_ofs)
    tiltX_ofs = -EDGE_MOVE_LIMIT
    return tiltX_ofs
end

-- Move to right end
-- * tiltX_ofs :    X-axis Tilt input
function tiltMoveRightEnd(tiltX_ofs)
    tiltX_ofs = EDGE_MOVE_LIMIT
    return tiltX_ofs
end

-- Move to bottom edge (by HotKey)
-- * tiltY_ofs :        Y-axis Tilt input
-- * tiltY_previous :   Y-axis Tilt input (previous frame)
function tiltMoveBottom(tiltY_ofs, tiltY_previous)
    if movie.isloaded() then
        if tiltY_ofs < tiltY_previous - NON_POP_RANGE then
            tiltY_ofs = tiltY_previous - NON_POP_RANGE
        elseif tiltY_ofs < tiltY_previous + NON_POP_RANGE then
            tiltY_ofs = tiltY_previous + NON_POP_RANGE
        else
            tiltY_ofs = EDGE_MOVE_LIMIT
        end
    else
        tiltY_ofs = EDGE_MOVE_LIMIT
    end
    if tiltY_ofs > EDGE_MOVE_LIMIT then
        tiltY_ofs = EDGE_MOVE_LIMIT
    end
    return tiltY_ofs
end

-- Move to center (by HotKey)
-- * tiltX_ofs :    X-axis Tilt input
-- * tiltY_ofs :    Y-axis Tilt input
function tiltMoveCenter(tiltX_ofs, tiltY_ofs)
    tiltX_ofs = 0
    tiltY_ofs = 0
    return tiltX_ofs, tiltY_ofs
end

-- Move to the Tilt of the previous frame (by HotKey)
-- * tiltX_ofs :    X-axis Tilt input
-- * tiltY_ofs :    Y-axis Tilt input
-- * tiltX_previous :   X-axis Tilt input (previous frame)
-- * tiltY_previous :   Y-axis Tilt input (previous frame)
function tiltMovePrevious()
    if  checkPreviousFrame() then
        tiltX_ofs = tiltX_previous
        tiltY_ofs = tiltY_previous
    else
        gui.addmessage("Movie not loaded")
    end
end

-- Grid move up (by HotKey)
-- * tiltY_ofs :    Y-axis Tilt input
function tiltMoveUp(tiltY_ofs)
    tiltY_ofs = adjustGridCalc(tiltY_ofs, false)
    tiltY_ofs = clampTiltLimit(tiltY_ofs)
    return tiltY_ofs
end

-- Grid shift to left (by HotKey)
-- * tiltX_ofs :    X-axis Tilt input
function tiltMoveLeft(tiltX_ofs)
    tiltX_ofs = adjustGridCalc(tiltX_ofs, false)
    tiltX_ofs = clampTiltLimit(tiltX_ofs)
    return tiltX_ofs
end

-- Grid shift to right (by HotKey)
-- * tiltX_ofs :    X-axis Tilt input
function tiltMoveRight(tiltX_ofs)
    tiltX_ofs = adjustGridCalc(tiltX_ofs, true)
    tiltX_ofs = clampTiltLimit(tiltX_ofs)
    return tiltX_ofs
end

-- Grid move down (by HotKey)
-- * tiltY_ofs :    Y-axis Tilt input
function tiltMoveDown(tiltY_ofs)
    tiltY_ofs = adjustGridCalc(tiltY_ofs, true)
    tiltY_ofs = clampTiltLimit(tiltY_ofs)
    return tiltY_ofs
end

-- Move up one (by HotKey)
-- * tiltY_ofs :    Y-axis Tilt input
function tiltMoveUpOne(tiltY_ofs)
    tiltY_ofs = tiltY_ofs - 1
    tiltY_ofs = clampTiltLimit(tiltY_ofs)
    return tiltY_ofs
end

-- Move left one (by HotKey)
-- * tiltX_ofs :    X-axis Tilt input
function tiltMoveLeftOne(tiltX_ofs)
    tiltX_ofs = tiltX_ofs - 1
    tiltX_ofs = clampTiltLimit(tiltX_ofs)
    return tiltX_ofs
end

-- Move right one (by HotKey)
-- * tiltX_ofs :    X-axis Tilt input
function tiltMoveRightOne(tiltX_ofs)
    tiltX_ofs = tiltX_ofs + 1
    tiltX_ofs = clampTiltLimit(tiltX_ofs)
    return tiltX_ofs
end

-- Move down one (by HotKey)
-- * tiltY_ofs :    Y-axis Tilt input
function tiltMoveDownOne(tiltY_ofs)
    tiltY_ofs = tiltY_ofs + 1
    tiltY_ofs = clampTiltLimit(tiltY_ofs)
    return tiltY_ofs
end

-- Draw input Tilt point
-- * tiltAreaX :    X-positon of TILT area start point (upper left)
-- * tiltAreaY :    Y-positon of TILT area start point (upper left)
-- * winSize :      window size
-- * tiltX :        TILT value on X-axis
-- * tiltY :        TILT value on Y-axis
-- * pointRad :     Radius of Tilt point
-- * color :        Color of Tilt point (by LuaColor)
function drawTilt(tiltAreaX, tiltAreaY, winSize, tiltX, tiltY, pointRad, color)
    local tiltXpos = tiltAreaX + TILT_INPUT_PADDING + 90 + tiltX
    local tiltYpos = tiltAreaY + TILT_INPUT_PADDING + 90 + tiltY
    gui.drawEllipse(tiltXpos - pointRad * winSize, tiltYpos - pointRad * winSize, pointRad * winSize * 2, pointRad * winSize * 2, color, color)
end

-- Draw Tilt Arrow
-- * tiltAreaCentralX : X-position (px) of the center of the TILT area
-- * tiltAreaCentralY : Y-position (px) of the center of the TILT area
-- * tiltX :        TILT value on X-axis
-- * tiltY :        TILT value on Y-axis
-- * color :        Color of Tilt point (by LuaColor)
function drawTiltArrow(tiltAreaCentralX, tiltAreaCentralY, tiltOutX, tiltOutY, color)
    local arrowHeadLengthRatio = 0.2    -- Arrowhead length as a percentage of total arrow length
    local arrowHeadWidthRatio = 0.1     -- Arrowhead width as a percentage of total arrow length
    local arrowShaftWidthRatio = 0.05   -- Shaft width as a percentage of arrow total length

    local tiltXpos = tiltOutX * TILT_ARROW_SCALE
    local tiltYpos = tiltOutY * TILT_ARROW_SCALE
    local tiltScalor = math.sqrt(tiltXpos * tiltXpos + tiltYpos * tiltYpos)

    -- Adjustment when arrow length exceeds a certain level.
    if tiltScalor > TILT_ARROW_MAX then
        tiltXpos = tiltXpos * (TILT_ARROW_MAX / tiltScalor)
        tiltYpos = tiltYpos * (TILT_ARROW_MAX / tiltScalor)
    end

    -- Drawing Arrow Polygon
    arrowPolygon = {}
    arrowPolygon[1] = {0, 0}
    arrowPolygon[2] = {math.floor(tiltXpos * (1 - arrowHeadLengthRatio) + tiltYpos * arrowShaftWidthRatio),
        math.floor(tiltYpos * (1 - arrowHeadLengthRatio) - tiltXpos * arrowShaftWidthRatio)}
    arrowPolygon[3] = {math.floor(tiltXpos * (1 - arrowHeadLengthRatio) + tiltYpos * arrowHeadWidthRatio),
        math.floor(tiltYpos * (1 - arrowHeadLengthRatio) - tiltXpos * arrowHeadWidthRatio)}
    arrowPolygon[4] = {math.floor(tiltXpos), math.floor(tiltYpos)}
    arrowPolygon[5] = {math.floor(tiltXpos * (1 - arrowHeadLengthRatio) - tiltYpos * arrowHeadWidthRatio),
        math.floor(tiltYpos * (1 - arrowHeadLengthRatio) + tiltXpos * arrowHeadWidthRatio)}
    arrowPolygon[6] = {math.floor(tiltXpos * (1 - arrowHeadLengthRatio) - tiltYpos * arrowShaftWidthRatio),
        math.floor(tiltYpos * (1 - arrowHeadLengthRatio) + tiltXpos * arrowShaftWidthRatio)}
    
    gui.drawPolygon(arrowPolygon, tiltAreaCentralX, tiltAreaCentralY, color, color)
end

----------------------
-- Callback process --
----------------------

-- ## Callback processing at state load
-- * Reflects userdata input
-- * If userdata does not exist, the input of the previous frame is reflected (only during recording)
function onLoadState()
    tiltX_ofs, tiltY_ofs = tiltMoveCenter(tiltX_ofs, tiltY_ofs)
    if userdata.containskey(saveXinput.key)
        and userdata.containskey(saveYinput.key)
        then
            tiltX_ofs = userdata.get(saveXinput.key)
            tiltY_ofs = userdata.get(saveYinput.key)
    elseif checkPreviousFrame() then
        tiltMovePrevious()
    end
end
event.onloadstate(onLoadState)  -- Fires at state load

-- ## Callback processing on exit
-- * Screen Initialization
function onExit()
    gui.clearGraphics()
    gui.cleartext()
    client.SetGameExtraPadding(0, 0, 0, 0)
end 
event.onexit(onExit)    -- Fires at end of script

---------------
-- Main loop --
---------------
while true do
    -- Clear GUI information
    gui.clearGraphics()
    gui.cleartext()

    -- Get Window Size
    local winSize = client.getwindowsize()

    -- Padding Settings(int left, int top, int right, int bottom)
    client.SetGameExtraPadding(EXPADDING_LEFT, EXPADDING_TOP, EXPADDING_RIGHT, EXPADDING_BOTTOM)

    -- Variable initialization
    local tiltY_sub = 0     -- Additive Y-coordinate for flip-up toggle

    -- Get Variables
    local existPrevFrame = checkPreviousFrame()
    local getInput = joypad.getimmediate()

    -- Switch to Controller input if available
    if controllerDetecter(getInput) and ENABLE_JOYPAD and not controllerEnable then
        controllerEnable = true
        gui.addmessage("Controller tilt enabled.")
    end
    
    --------------------------------
    -- Memory Information Display --
    --------------------------------

    -- Get Memory
    -- coordinate memory address
    local memory_Xpos = memory.read_s16_be(0xFFA5)  -- Kirby's X-position
    local memory_Xspx = memory.read_u8(0xFFA7)      -- Kirby's X-subpixel
    local memory_Zpos = memory.read_s16_be(0xFFA8)  -- Kirby's Z-position
    local memory_Zspx = memory.read_u8(0xFFAA)      -- Kirby's Z-subpixel
    local memory_Ypos = memory.read_s16_be(0xFFAB)  -- Kirby's Y-position
    local memory_Yspx = memory.read_u8(0xFFAD)      -- Kirby's Y-subpixel

    -- speed memory address
    local memory_Xspd = memory.read_s16_be(0xFFD2)  -- Kirby's X-speed
    local memory_Zspd = memory.read_s16_be(0xFFD4)  -- Kirby's Z-speed
    local memory_Yspd = memory.read_s16_be(0xFFD6)  -- Kirby's Y-speed

    -- Output Tilt Memory Address
    local memory_tiltOutX = memory.read_u16_be(0xFFF3)  -- Output X-axis TILT
    local memory_tiltOutY = memory.read_u16_be(0xFFF5)  -- Output Y-axis TILT
    local memory_tiltFlatX = memory.read_u16_be(0xFFF7) -- Reference X-axis TILT
    local memory_tiltFlatY = memory.read_u16_be(0xFFF9) -- Reference Y-axis TILT

    -- Other memory address
    local stopTime = memory.read_s16_be(0xE28C) -- Time for Kirby to stop.

    -- Output Tilt
    tiltOutX = tiltConvertor(memory_tiltOutX, memory_tiltFlatX)
    tiltOutY = tiltConvertor(memory_tiltOutY, memory_tiltFlatY)

    -- Text drawing
    -- Coordinate memory display
    local group1_x = INFO_OFS_X + 0
    local group1_y = INFO_OFS_Y + 0
    local group1_indent = 24

    local memory_Xpos_db = string.format("%d:%03d", memory_Xpos, memory_Xspx)
    local memory_Zpos_db = string.format("%d:%03d", memory_Zpos, memory_Zspx)
    local memory_Ypos_db = string.format("%d:%03d", memory_Ypos, memory_Yspx)

    gui.text(group1_x, group1_y + INFO_ROW_HEIGHT * 0, "- Position -", "white")

    gui.text(group1_x, group1_y + INFO_ROW_HEIGHT * 1, "X:", "red")
    gui.text(group1_x + group1_indent, group1_y + INFO_ROW_HEIGHT * 1, memory_Xpos_db, "white");

    gui.text(group1_x, group1_y + INFO_ROW_HEIGHT * 2, "Z:", "blue")
    gui.text(group1_x + group1_indent, group1_y + INFO_ROW_HEIGHT * 2, memory_Zpos_db, "white");

    gui.text(group1_x, group1_y + INFO_ROW_HEIGHT * 3, "Y:", "green")
    gui.text(group1_x + group1_indent, group1_y + INFO_ROW_HEIGHT * 3, memory_Ypos_db, "white");

    -- Speed memory display
    local group2_x = INFO_OFS_X + 144
    local group2_y = INFO_OFS_Y + 0
    local group2_indent = 24

    gui.text(group2_x, group2_y + INFO_ROW_HEIGHT * 0, "- Speed -", "white")

    gui.text(group2_x, group2_y + INFO_ROW_HEIGHT * 1, "X:", "red")
    gui.text(group2_x + group2_indent, group2_y + INFO_ROW_HEIGHT * 1, memory_Xspd, "white");

    gui.text(group2_x, group2_y + INFO_ROW_HEIGHT * 2, "Z:", "blue")
    gui.text(group2_x + group2_indent, group2_y + INFO_ROW_HEIGHT * 2, memory_Zspd, "white");

    gui.text(group2_x, group2_y + INFO_ROW_HEIGHT * 3, "Y:", "green")
    gui.text(group2_x + group2_indent, group2_y + INFO_ROW_HEIGHT * 3, memory_Yspd, "white");

    -- Other Information
    local group3_x = INFO_OFS_X + 256
    local group3_y = INFO_OFS_Y + 0

    gui.text(group3_x, group3_y + INFO_ROW_HEIGHT * 0, "- Other -", "white")
    gui.text(group3_x, group3_y + INFO_ROW_HEIGHT * 1, "StopTime:", "white")
    gui.text(group3_x + 92, group3_y + INFO_ROW_HEIGHT * 1, stopTime, "white");

    --------------------
    -- Tilt input GUI --
    --------------------
    -- Table of whether there is an input
    local pressedTable = {}

    -- Get Mouse Input
    local mouseL = input.getmouse().Left
    table.insert(pressedTable, mouseL)

    -- Get keyboard input
    local inputTable = input.get()
    table.insert(pressedTable, isKeyPressed(keyUpOne, inputTable))
    table.insert(pressedTable, isKeyPressed(keyDownOne, inputTable))
    table.insert(pressedTable, isKeyPressed(keyLeftOne, inputTable))
    table.insert(pressedTable, isKeyPressed(keyRightOne, inputTable))

    table.insert(pressedTable, isKeyPressed(keyMoveUp, inputTable))
    table.insert(pressedTable, isKeyPressed(keyMoveDown, inputTable))
    table.insert(pressedTable, isKeyPressed(keyMoveLeft, inputTable))
    table.insert(pressedTable, isKeyPressed(keyMoveRight, inputTable))
    -- isKeyPressed(keyMoveUpLeft, inputTable)
    -- isKeyPressed(keyMoveUpRight, inputTable)
    -- isKeyPressed(keyMoveDownLeft, inputTable)
    -- isKeyPressed(keyMoveDownRight, inputTable)
    table.insert(pressedTable, isKeyPressed(keyMoveCenter, inputTable))
    table.insert(pressedTable, isKeyPressed(keyMovePrevious, inputTable))

    table.insert(pressedTable, isKeyPressed(keyUpLast, inputTable))
    table.insert(pressedTable, isKeyPressed(keyDownLast, inputTable))
    table.insert(pressedTable, isKeyPressed(keyLeftLast, inputTable))
    table.insert(pressedTable, isKeyPressed(keyRightLast, inputTable))

    table.insert(pressedTable, isKeyPressed(keyPopToggle, inputTable))

    -- Disable Controller input if key-mouse input is available
    for i, value in pairs(pressedTable) do
        if value and controllerEnable then
            controllerEnable = false
            gui.addmessage("Controller tilt disabled.")
        end
    end

    -- Set the position of the Tilt input area
    local tiltAreaX = EXPADDING_LEFT + client.bufferwidth() + EXPADDING_RIGHT - (AXIS_SIZE + TILT_INPUT_PADDING) * 2
    local tiltAreaY = EXPADDING_TOP + client.bufferheight() + EXPADDING_BOTTOM - (AXIS_SIZE + TILT_INPUT_PADDING) * 2

    -- Center coordinates of Tilt input area
    local tiltAreaCentralX = tiltAreaX + TILT_INPUT_PADDING + AXIS_SIZE
    local tiltAreaCentralY = tiltAreaY + TILT_INPUT_PADDING + AXIS_SIZE

    -- Drawing grid box
    for i = TILT_MOVE_GRID, AXIS_SIZE, TILT_MOVE_GRID do
        gui.drawLine(tiltAreaCentralX + i, tiltAreaCentralY - AXIS_SIZE, tiltAreaCentralX + i, tiltAreaCentralY + AXIS_SIZE, "#333333")
        gui.drawLine(tiltAreaCentralX - AXIS_SIZE, tiltAreaCentralY + i, tiltAreaCentralX + AXIS_SIZE, tiltAreaCentralY + i, "#333333")
        gui.drawLine(tiltAreaCentralX - i, tiltAreaCentralY - AXIS_SIZE, tiltAreaCentralX - i, tiltAreaCentralY + AXIS_SIZE, "#333333")
        gui.drawLine(tiltAreaCentralX - AXIS_SIZE, tiltAreaCentralY - i, tiltAreaCentralX + AXIS_SIZE, tiltAreaCentralY - i, "#333333")
    end
    -- Tilt Limit Frame Drawing
    gui.drawRectangle(tiltAreaCentralX - EDGE_MOVE_LIMIT, tiltAreaCentralY - EDGE_MOVE_LIMIT, EDGE_MOVE_LIMIT * 2, EDGE_MOVE_LIMIT * 2, "#999999")

    -- Drawing coordinate axis
    gui.drawAxis(tiltAreaCentralX, tiltAreaCentralY, AXIS_SIZE, "blue")

    -- Drawing the outer frame
    gui.drawRectangle(tiltAreaCentralX - AXIS_SIZE, tiltAreaCentralY - AXIS_SIZE, AXIS_SIZE * 2, AXIS_SIZE * 2, "#FFFFFF")

    -- Draw pixel text
    gui.pixelText(tiltAreaCentralX - AXIS_SIZE - 18, tiltAreaCentralY - 3, "X-90")
    gui.pixelText(tiltAreaCentralX + AXIS_SIZE + 2, tiltAreaCentralY - 3, "X+90")
    gui.pixelText(tiltAreaCentralX - 7, tiltAreaCentralY - AXIS_SIZE - 7, "Y-90")
    gui.pixelText(tiltAreaCentralX - 7, tiltAreaCentralY + AXIS_SIZE + 1, "Y+90")

    if controllerEnable then
        tiltX, tiltY = getInput["P1 Tilt X"], getInput["P1 Tilt Y"]
    else
        -- Initialization of tilt input
        inputTable[INPUT_TILTX] = 0
        inputTable[INPUT_TILTY] = 0
        joypad.setanalog(inputTable)

        -- Hotkey Reflection

        -- if keyMoveUpLeft["pressed"] then
        --     tiltY_ofs = tiltMoveTop(tiltY_ofs, tiltY_previous)
        --     tiltX_ofs = tiltMoveLeftEnd(tiltX_ofs)
        -- end

        -- if keyMoveUpRight["pressed"] then
        --     tiltY_ofs = tiltMoveTop(tiltY_ofs, tiltY_previous)
        --     tiltX_ofs = tiltMoveRightEnd(tiltX_ofs)
        -- end

        -- if keyMoveDownLeft["pressed"] then
        --     tiltY_ofs = tiltMoveBottom(tiltY_ofs, tiltY_previous)
        --     tiltX_ofs = tiltMoveLeftEnd(tiltX_ofs)
        -- end

        -- if keyMoveDownRight["pressed"] then
        --     tiltY_ofs = tiltMoveBottom(tiltY_ofs, tiltY_previous)
        --     tiltX_ofs = tiltMoveRightEnd(tiltX_ofs)
        -- end

        if keyMoveCenter["pressed"] then
            tiltX_ofs, tiltY_ofs = tiltMoveCenter(tiltX_ofs, tiltY_ofs)
        end

        if keyMovePrevious["pressed"] then
            tiltMovePrevious()
        end

        if keyUpOne["pressed"] then
            tiltY_ofs = tiltMoveUpOne(tiltY_ofs)
        elseif keyMoveUp["pressed"] then
            tiltY_ofs = tiltMoveUp(tiltY_ofs)
        end

        if keyLeftOne["pressed"] then
            tiltX_ofs = tiltMoveLeftOne(tiltX_ofs)
        elseif keyMoveLeft["pressed"] then
            tiltX_ofs = tiltMoveLeft(tiltX_ofs)
        end

        if keyRightOne["pressed"] then
            tiltX_ofs = tiltMoveRightOne(tiltX_ofs)
        elseif keyMoveRight["pressed"] then
            tiltX_ofs = tiltMoveRight(tiltX_ofs)
        end

        if keyDownOne["pressed"] then
            tiltY_ofs = tiltMoveDownOne(tiltY_ofs)
        elseif keyMoveDown["pressed"] then
            tiltY_ofs = tiltMoveDown(tiltY_ofs)
        end

        if keyUpLast["pressed"] then
            tiltY_ofs = tiltMoveTop(tiltY_ofs, tiltY_previous)
        end

        if keyLeftLast["pressed"] then
            tiltX_ofs = tiltMoveLeftEnd(tiltX_ofs)
        end

        if keyRightLast["pressed"] then
            tiltX_ofs = tiltMoveRightEnd(tiltX_ofs)
        end

        if keyDownLast["pressed"] then
            tiltY_ofs = tiltMoveBottom(tiltY_ofs, tiltY_previous)
        end

        if keyPopToggle["current"] then
            tiltY_sub = POP_RANGE
        end

        -- Reflects mouse clicks
        if mouseL and ENABLE_CLICK then
            local tiltMouseX = input.getmouse().X - (tiltAreaX - EXPADDING_LEFT + TILT_INPUT_PADDING)
            local tiltMouseY = input.getmouse().Y - (tiltAreaY - EXPADDING_TOP + TILT_INPUT_PADDING)

            if tiltMouseX >= -TILT_INPUT_PADDING and tiltMouseX <= (TILT_INPUT_PADDING + AXIS_SIZE) * 2 then
                if tiltMouseY >= -TILT_INPUT_PADDING and tiltMouseY <= (TILT_INPUT_PADDING + AXIS_SIZE) * 2 then
                    -- Update tilt position
                    tiltX_ofs = math.floor(tiltMouseX - 90 + 0.5)
                    tiltY_ofs = math.floor(tiltMouseY - 90 + 0.5)
                end
            end
        end

        -- Reflection of Final Tilt
        tiltX = tiltX_ofs
        tiltY = tiltY_ofs + tiltY_sub

        -- Final Tilt Correction
        tiltX = clampTilt(tiltX)
        tiltY = clampTilt(tiltY)
    end
    
    -- Text drawing of Tilt value
    gui.text((tiltAreaX + TILT_INPUT_PADDING) * winSize, (tiltAreaY + TILT_INPUT_PADDING) * winSize - 50, "TILT IN: ", "#FFFFFF")
    gui.text((tiltAreaX + TILT_INPUT_PADDING) * winSize + 100, (tiltAreaY + TILT_INPUT_PADDING) * winSize - 50, "X: " .. tiltX .. " Y: " .. tiltY, "#FF6666")

    gui.text((tiltAreaX + TILT_INPUT_PADDING) * winSize, (tiltAreaY + TILT_INPUT_PADDING) * winSize - 32, "TILT OUT: ", "#FFFFFF")
    gui.text((tiltAreaX + TILT_INPUT_PADDING) * winSize + 100, (tiltAreaY + TILT_INPUT_PADDING) * winSize - 32, "X: " .. tiltOutX .. " Y: " .. tiltOutY, "#FF6666")

    if checkPreviousFrame() then
        gui.text((tiltAreaX + TILT_INPUT_PADDING + (AXIS_SIZE * 2)) * winSize - 128, (tiltAreaY + TILT_INPUT_PADDING) * winSize - 50, "X: " .. tiltX_previous .. " Y: " .. tiltY_previous, "#00FF00")
    end

    -- Drawing Tilt Arrows
    if ENABLE_TILT_ARROW then
        drawTiltArrow(tiltAreaCentralX, tiltAreaCentralY, tiltOutX, tiltOutY, "#CCFF3333")
    end

    -- Drawing Tilt input
    local tiltColor = "#FF6666"
    if tiltX == 0 and tiltY == 0 then
        tiltColor = "#0000FF"
    end
    if existPrevFrame and movie.getreadonly() == false then
        if tiltY < tiltY_previous - NON_POP_RANGE or tiltY > tiltY_previous + NON_POP_RANGE then
            tiltColor = "#FF0000"
        end
    end

    drawTilt(tiltAreaX, tiltAreaY, winSize, tiltX, tiltY, POINT_RAD, tiltColor)

    -- Reflects Tilt input from previous frame (during recording only)
    if existPrevFrame then
        local inputPrevious = movie.getinput(emu.framecount() - 1)
        tiltX_previous = inputPrevious[INPUT_TILTX]
        tiltY_previous = inputPrevious[INPUT_TILTY]
        drawTilt(tiltAreaX, tiltAreaY, winSize, tiltX_previous, tiltY_previous, POINT_RAD_PREVIOUS, "#00FF00")

        -- Display of pop prevention line
        if movie.getreadonly() == false then
            local nonPopTopY = tiltAreaCentralY + tiltY_previous - NON_POP_RANGE
            if nonPopTopY < tiltAreaY + TILT_INPUT_PADDING then
                nonPopTopY = tiltAreaY + TILT_INPUT_PADDING
            end

            local nonPopBottomY = tiltAreaCentralY + tiltY_previous + NON_POP_RANGE
            if nonPopBottomY > tiltAreaCentralY * 2  then
                nonPopBottomY = tiltAreaCentralY * 2
            end

            gui.drawLine(tiltAreaX + TILT_INPUT_PADDING, nonPopTopY, tiltAreaCentralX * 2, nonPopTopY, "#006600")

            gui.drawLine(tiltAreaX + TILT_INPUT_PADDING, nonPopBottomY, tiltAreaCentralX * 2, nonPopBottomY, "#006600")
        end
    end

    -- Reflects input to BizHawk
    inputTable[INPUT_TILTX] = tiltX
    inputTable[INPUT_TILTY] = tiltY
    joypad.setanalog(inputTable)

    -- Save input to userdata
    saveXinput.value = tiltX_ofs
    saveYinput.value = tiltY_ofs
    userdata.set(saveXinput.key, saveXinput.value)
    userdata.set(saveYinput.key, saveYinput.value)

    -- loopback
    emu.yield()
end
