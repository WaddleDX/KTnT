# Kirby Tilt 'n' Tumble: Lua for TAS v2.0
Script optimized for TAS. It has the following features:
- Various memory watches
- More convenient tilt input
- Tilt Output Arrow

<img src="image000.png" alt="screenshot" width="500">

----

## Note: Difference from version 1.0
- Major changes were made to the operation with keyboard input. Input using the numeric keypad has been eliminated, and input is now performed using the arrow keys and Ctrl/Shift key combination.
- Input is now accepted at the controller even while a script is running.
- Added the ability to change whether or not mouse click input is accepted, which can be changed from ```ENABLE_CLICK``` in the Lua file.
- Fixed some bugs.

## Memory watches
There is a separate item to store the speed and the time it takes for Kirby to enter the waiting motion. x and z are the horizontal and vertical axes parallel to the ground, and y is the axis perpendicular to the ground.

Position memory concatenates pixel positions with sub-pixel(0-255) positions.

## Tilt Input
TILT input can be entered by arrow keys or mouse click. While loading a movie, the tilt input for the previous frame is also displayed.

The following is a guide to keyboard operation.


### Arrow keys
Pressing the arrow keys moves the Tilt input in alignment with the grid. The spacing of this grid can be changed from the value of ```TILT_MOVE_GRID``` in the lua file.

Tilt can be moved by 1 by pressing it together with **Ctrl**.

Press **Ctrl+Shift** together to move to the edge of the Tilt area. If ```EDGE_MOVE_LIMIT``` is set to less than 90, the edge will shrink to that width. If a movie is being recorded/played, Kirby will slide to the line (green by default) where he will not jump.

### Home key
Move Tilt to the center.

### Page Down Key
Increases Tilt input by 18 on the Y axis while pressed. This is the approximate minimum tilt difference that Kirby will jump. Note, however, that depending on the output Tilt, it may not jump.

### End Key
If a movie is being recorded/played back, the current Tilt input is moved to the Tilt input of the previous frame.

## Tilt Output
This tilt is calculated and output in-game. Kirby's movement is affected by this output tilt.

Tilt Output is indicated by a red translucent arrow. The direction of the arrow indicates the direction of the tilt, and the size of the arrow indicates the magnitude of the tilt. This arrow can be disabled by ```ENABLE_TILT_ARROW```.

## Notices
- A minimum window size of 2x is recommended. It will be automatically adjusted when the script is loaded.
- It works with **BizHawk version 2.8** or higher. Earlier versions have not been tested.
- The core only works with **Gambatte (SameBoy)**; Tilt input is not possible with GBHawk.