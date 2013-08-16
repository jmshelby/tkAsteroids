package require Tclx


# Init Variables
set flag(upKey_down) 0
set flag(leftKey_down) 0
set flag(rightKey_down) 0
set flag(spaceKey_down) 0
set flag(SKey_down) 0

# Constants
set refresh 1
set pi 3.141592654
#set pi 3.1415926535897932384626433832795
set gravity(dir_velocity_vec) {0 0}

# Ship Coord Configs
set polygon(smallShip) {0 5 5 -5 0 -2 -5 -5 0 5}
set polygon(smallShip2) {100 105 105 95 100 98 95 95 100 105}
set polygon(largeShip) {0 20 1 19 1 17 2 16 2 4 6 3 6 6 7 7 7 8 8 9 9 8 9 7 10 6 10 1 16 -3 16 -4 10 -4 10 -6 8 -7 6 -6 6 -4 -6 -4 -6 -6 -8 -7 -10 -6 -10 -4 -16 -4 -16 -3 -10 1 -10 6 -9 7 -9 8 -8 9 -7 8 -7 7 -6 6 -6 3 -2 4 -2 16 -1 17 -1 19 0 20}
set polygon(plane) {0 19 3 16 3 3 18 1 20 -3 3 -3 3 -15 10 -17 10 -18 -10 -18 -10 -17 -3 -15 -3 -3 -20 -3 -18 1 -3 3 -3 16 0 19}
set polygon(erics_ship) { 0 10 10 -10      6 -8 6 -13 5 -15 4 -13 4 -8 0 -6 -4 -8 -4 -13 -5 -15 -6 -13 -6 -8   -10 -10      -2 6 -2 3 0 4 2 3 2 6 0 7 -2 6 0 10 }
set polygon(erics_ship2) { 0 10 10 -10      6 -8 6 -13 5 -15 4 -13 4 -8 0 -6 -4 -8 -4 -13 -5 -15 -6 -13 -6 -8   -10 -10      -2 6 -2 3 0 4 2 3 2 6 0 7 -2 6 0 10 }

# Graphics Engine Configs
set sprite(ship,init_pos) $polygon(smallShip)
set sprite(ship,center_pos) {0 0}
set sprite(ship,dir_velocity_vec:new) {0 0}
set sprite(ship,dir_velocity_vec:old) {0 0}
set sprite(ship,scale:x) 6
set sprite(ship,scale:y) 6
set sprite(ship,rotate_velocity) .05
set sprite(ship,forward_velocity) .1
set sprite(ship,current_dir_angle) [expr $pi / 2]

# Build the GUI elements
canvas .c -background black
pack .c -expand yes -fill both
.c create polygon $sprite(ship,init_pos) -fill blue -outline green -tag ship ;# -joinstyle round -smooth true ;#-spline 1
.c scale ship 0 0 $sprite(ship,scale:x) $sprite(ship,scale:y)

proc move_sprite {sprite {Xincr {1}} {Yincr {1}}} {
    global sprite
    .c move $sprite $Xincr $Yincr
    lassign $sprite(ship,center_pos) cen_x cen_y
    set newX [expr $Xincr + $cen_x]
    set newY [expr $Yincr + $cen_y]
    set sprite(ship,center_pos) [list $newX $newY]
}

# proc that will Rotate The Ship by the theta_incr
# The theta_incr is the angle amount that should be rotated
proc rotate_ship {theta_incr} {
    global sprite pi
    foreach {x y} [.c coords ship] {
        lassign $sprite(ship,center_pos) cen_x cen_y

        # Subtract back to origin
        set x [expr $x - $cen_x]
        set y [expr $y - $cen_y]
        # Calculate new sprite end-points
        set newX  [expr cos($theta_incr) * $x - sin($theta_incr) * $y]
        set newY  [expr sin($theta_incr) * $x + cos($theta_incr) * $y]
        # Add back to current pos
        set newX [expr $newX + $cen_x]
        set newY [expr $newY + $cen_y]

        lappend newCoords $newX $newY
    }

    # Redraw sprite with new coords
    .c coords ship $newCoords
    # Update the current_dir_angle variable
    set sprite(ship,current_dir_angle) [expr $sprite(ship,current_dir_angle) + $theta_incr]
}


# proc that moves the ship in the direction of the current
#  values in the sprite(ship,dir_velocity_vec:new) array.
# Moves sprite for one animation cycle.
proc moveShip_currentDir {} {
    global sprite

    lassign $sprite(ship,dir_velocity_vec:new) x_distance y_distance
    lassign $sprite(ship,center_pos) cen_x cen_y

    set new_x [expr $cen_x + $x_distance]
    set new_y [expr $cen_y + $y_distance]

    set sprite(ship,center_pos) [list $new_x $new_y]
    .c move ship $x_distance $y_distance
}

# proc that calculates the :new velocity vector for the sprite
#   based off of the current direction angle of the sprite, as
#   well as the forward_velocity setting of the sprite.
# this proc does not actually move the sprite, moveShip_currentDir
#   is called for that.
proc new_dir_velocity_vec {} {
    global sprite
    set sprite(ship,dir_velocity_vec:old) $sprite(ship,dir_velocity_vec:new)
    #
    set theta $sprite(ship,current_dir_angle)
    set x_incr [expr cos($theta) * $sprite(ship,forward_velocity)]
    set y_incr [expr sin($theta) * $sprite(ship,forward_velocity)]
    #
    set x_incr [expr [lindex $sprite(ship,dir_velocity_vec:old) 0] + $x_incr]
    set y_incr [expr [lindex $sprite(ship,dir_velocity_vec:old) 1] + $y_incr]
    #
    set sprite(ship,dir_velocity_vec:new) [list $x_incr $y_incr]
}

# Moves the sprites location directly to the specified x and y
#   coords. Does not animate the move.
proc putShip_at {atX atY} {
    global sprite

    lassign $sprite(ship,center_pos) curX curY
    set x_incr [expr $atX - $curX]
    set y_incr [expr $atY - $curY]

    set sprite(ship,center_pos) [list $atX $atY]
    .c move ship $x_incr $y_incr
}

# Proc is used to add gravity to the environment,
# Adds gravity for one animation cycle
proc add_gravity {} {
    global sprite gravity
    set sprite(ship,dir_velocity_vec:old) $sprite(ship,dir_velocity_vec:new)
    #
    set x_incr [expr [lindex $sprite(ship,dir_velocity_vec:old) 0] + [lindex $gravity(dir_velocity_vec) 0]]
    set y_incr [expr [lindex $sprite(ship,dir_velocity_vec:old) 1] + [lindex $gravity(dir_velocity_vec) 1]]
    #
    set sprite(ship,dir_velocity_vec:new) [list $x_incr $y_incr]
}

# This proc is to keep the sprite in the context of the screen.
# Just relocates the sprite to the opposite side of the screen.
proc relocateShip_ifGone {} {
    global sprite
    if {[lindex $sprite(ship,center_pos) 0] > [winfo width .c]} then {putShip_at 0 [lindex $sprite(ship,center_pos) 1]}
    if {[lindex $sprite(ship,center_pos) 0] < 0} then {putShip_at [winfo width .c] [lindex $sprite(ship,center_pos) 1]}

    if {[lindex $sprite(ship,center_pos) 1] > [winfo height .c]} then {putShip_at [lindex $sprite(ship,center_pos) 0] 0}
    if {[lindex $sprite(ship,center_pos) 1] < 0} then {putShip_at [lindex $sprite(ship,center_pos) 0] [winfo height .c]}
}

# This is the main driving proc, keeps the animation cycles going,
# as well as calls the procs for moving and calculating new directions
# and rotations based off of keypress states.
proc ast_timer {} {
    global sprite flag refresh
    if $flag(upKey_down)    then {new_dir_velocity_vec}
    if $flag(leftKey_down)  then {rotate_ship [expr -1 * $sprite(ship,rotate_velocity)]}
    if $flag(rightKey_down) then {rotate_ship $sprite(ship,rotate_velocity)}
    if $flag(SKey_down)     then {set sprite(ship,dir_velocity_vec:new) {0 0}}
    moveShip_currentDir
    add_gravity
    relocateShip_ifGone
    update idletasks
    after $refresh ast_timer
}

# Bind all key press events
bind . <KeyPress-Left> {set flag(leftKey_down) 1}
bind . <KeyPress-Right> {set flag(rightKey_down) 1}
bind . <KeyPress-Up> {set flag(upKey_down) 1}
bind . <KeyPress-space> {set flag(spaceKey_down) 1}
bind . <KeyPress-S> {set flag(SKey_down) 1}

bind . <KeyRelease-Left> {set flag(leftKey_down) 0}
bind . <KeyRelease-Right> {set flag(rightKey_down) 0}
bind . <KeyRelease-Up> {set flag(upKey_down) 0}
bind . <KeyRelease-space> {set flag(spaceKey_down) 0}
bind . <KeyRelease-S> {set flag(SKey_down) 0}


# Start the animation cycle
ast_timer

