; Vince Derayunan, Lucas Ramos-Strankman, Nanjia Wang
; CPSC 565
; Winter 2020
; Catan Project

; TILE LEGEND:
; GREEN -> WOOD
; ORANGE -> BRICK
; YELLOW -> WHEAT
; WHITE -> SHEEP

globals [ turnNum weights rWood rBrick rWheat rSheep rVPoints]
breed [ player1 red-player]

patches-own [ tileValue ]

; returns the array of weights to judge a spot by
to-report settlement-weights
  report (list woodWeight brickWeight wheatweight sheepWeight distWeight)
end

to setup
  ca
  set turnNum 0
  setup-patches
  setup-turtles
  display-labels
end



; This is where the dice rolls and the player turns will happen
to go
  set turnNum turnNum + 1
  if show-details? [type "Turn " print turnNum]
  display-labels ; get the patches to display their prob-values
  roll-dice ;Rolls dice and gives resources
  redturn
end



; Gives the patches labels for their roll values
to display-labels
  ask patches [ set plabel "" set plabel-color black]
  if show-value? [
    ask patches [
      if pcolor != 1 and pcolor != sky and pcolor != red
        [ set plabel tileValue]
    ]
  ]
end



; This defines what the red-player does
to redTurn

  let goal find-best-patch red   ; Where it tries to build next settlement
  let buildFrom 0
  let buildNext 0


  ;Find the closest structure to the goal to build from
  ask goal [
   let temp closest-structure red
   ifelse temp != nobody
        [ set buildFrom item 1 closest-structure red ] ; The closest structure to the goal
      [ set buildFrom nobody ]

  ]

  ;Find the next spot to build on, on way to goal
  if buildFrom != nobody[
    ;Find the current structure we are building off of, find the patch we are building onto
    ask buildFrom[
      let closest (list 10000 self)
      ask neighbors4[
        let temp distance goal
        if is-valid-road and temp < first closest [
          set closest (list temp self)
        ]
        set buildNext item 1 closest
      ]
    ]


    ; If we are building onto the goal, build a settlement
    ;otherwise, build a road
    ifelse buildNext = goal
    [ try-build-settlement buildNext ]
    [ try-build-road buildNext ]

    if show-details?
    [ type "Goal: " print goal
      type "BuildFrom: " print buildFrom
      type "BuildNext: " print buildNext
    ]
  ]
end


;Builds a settlement if it has the resources
to try-build-settlement [destination]
  if has-settlement-resources [
    set rWood rWood - 1
    set rBrick rBrick - 1
    set rWheat rWheat - 1
    set rSheep rSheep - 1
    set rVPoints rVPoints + 1
;    create-red-settlement destination
    ask destination [
      sprout-player1 1 [
        set shape "house"
        set color red
      ]
    ]
  ]
end



;Currently only setup to work for Red
to try-build-road [destination]
  if has-road-resources [
    set rWood rWood - 1
    set rBrick rBrick - 1
    ask destination [set pcolor red]
  ]
end


;Currently only setup to work for Red
to-report has-road-resources
  if rWood > 0 and rBrick > 0 [
    report true
  ]
  report false
end


;Currently only setup to work for Red
to-report has-settlement-resources
  if rWood > 1 and rBrick > 1 and rWheat > 1 and rSheep > 1 [
    report true
  ]
  report false
end


; Rolls dice and gives resources
to roll-dice
  let roll random 6 + random 6
  ask patches [
    if tileValue = roll [
      give-resources pcolor
    ]
  ]
  if show-details? [ type "Dice Roll: " print roll ]
end

; Makes a patch gives its resources to neighby settlements
to give-resources [rType]
  ask neighbors [
   ask turtles-here [
     (ifelse
      rType = green [
        set rWood rWood + 1
      ]
       rType = orange [
        set rBrick rBrick + 1
      ]
       rType = yellow [
        set rWheat rWheat + 1
      ]
       rType = white [
        set rSheep rSheep + 1
      ]
       rType = brown or rType = 1 or rType = red [
        ; do nothing, this is a desert or road
      ])
    ]
  ]
end


; Helper for give-resources
; Works to give to the correct player i.e. red vs. blue etc.
to add-player-resources [rType]
;  if color = red [ ; if it is a red settlement
    (ifelse
      rType = green [
        set rWood rWood + 1
      ]
       rType = orange [
        set rBrick rBrick + 1
      ]
       rType = yellow [
        set rWheat rWheat + 1
      ]
       rType = white [
        set rSheep rSheep + 1
      ]
       rType = brown or rType = 1 or rType = red [
        ; do nothing, this is a desert or road
      ])
end


; Returns the patch the player next wants to build a settlement on
; based on our array of weights
to-report find-best-patch [col]
  let bestFound (list -100000000 patch 0 0) ; quality, patch
  let temp 0
  ask patches [
    if is-valid-settlement[
      set temp rate-settlement col
      if temp > item 0 bestfound [
        set bestfound (list temp self)
      ]
    ]
  ]
  report item 1 bestfound ;return the best patch
end


;Rates how good a settlement is based off our (global variable) settlement-weights array
to-report rate-settlement [col]

  let woodQual (find-resource green * item 0 settlement-weights)
  let brickQual (find-resource orange * item 1 settlement-weights)
  let wheatQual (find-resource yellow * item 2 settlement-weights)
  let sheepQual (find-resource white * item 3 settlement-weights)
  let dist closest-structure red
  let distQual 0
  if dist != nobody
     [ set distQual (first dist * item 4 settlement-weights) ]

  report woodQual + brickQual + wheatQual + sheepQual - distQual
end


; Finds the closest road or settlement of the given color
; To the calling agent
to-report closest-structure [col]
  let x pxcor
  let y pycor
  let nearestSettlement min-one-of turtles with [color = col and not blocked-in patch-here] [distancexy x y]
  if nearestSettlement != nobody [
    set nearestSettlement (list distance nearestSettlement nearestSettlement)
  ]

  let nearestPatch min-one-of patches with [pcolor = col and not blocked-in self] [distancexy x y]
  if nearestPatch != nobody
     [  set nearestPatch (list distance nearestPatch nearestPatch) ]

  if nearestSettlement = nobody and nearestPatch = nobody [
    report nobody
  ]
  if nearestSettlement = nobody
    [ report nearestPatch ]
  if nearestPatch = nobody
    [ report nearestSettlement ]

  ifelse first nearestSettlement < first nearestPatch
     [ report nearestSettlement ]
     [ report nearestPatch]

end




; Finds the expected production of the tile
to-report convert-tileValue [prob]
  if (prob = 0 or prob = 10) [ report 1 ]
  if (prob = 1 or prob = 9) [ report 2 ]
  if (prob = 2 or prob = 8) [ report 3 ]
  if (prob = 3 or prob = 7) [ report 4 ]
  if (prob = 4 or prob = 5 or prob = 6) [ report 5 ] ; This is because we dont have a robber
end


; Finds the expected production of a resource type (val)
; from a given patch
to-report find-resource [val]
 let w 0
  if ([pcolor] of patch-at 1 1 = val) [
     set w w + convert-tileValue [tileValue] of patch-at 1 1]
  if ([pcolor] of patch-at 1 -1 = val) [
    set w w + convert-tileValue [tileValue] of patch-at 1 -1 ]
  if ([pcolor] of patch-at -1 1 = val) [
   set w w + convert-tileValue [tileValue] of patch-at -1 1]
  if ([pcolor] of patch-at 1 1 = val) [
   set w w + convert-tileValue [tileValue] of patch-at -1 -1]
  report w
end





; Checks of a road can be built on
to-report is-valid-road
  if (pcolor != 1) or ; out of bounds or other road there
     (any? turtles-on self) ; There is a settlement on this patch
     [ report false ]
  report true
end


; Checks if a settlement can be built
to-report is-valid-settlement
  if (pcolor != 1) [ ; out of bounds or other road there
    report false
  ]

  ; There is already a settlement there
  if any? turtles-on patch-at 0 0 or ; Two away
  any? turtles-on patch-at 0 2 or
  any? turtles-on patch-at 0 -2 or
  any? turtles-on patch-at 2 0 or
  any? turtles-on patch-at -2 0 or
  any? turtles-on patch-at 0 1 or   ; Right next to another settlement
  any? turtles-on patch-at 0 -1 or
  any? turtles-on patch-at 1 0 or
  any? turtles-on patch-at -1 0 or
  any? turtles-on patch-at 1 1 or   ; Corner to a settlement
  any? turtles-on patch-at 1 -1 or
  any? turtles-on patch-at -1 1 or
  any? turtles-on patch-at -1 -1 [
  report false
  ]

  report true
end


to-report blocked-in [pat]
  let result true
  ask pat[
   ask neighbors4[
     if is-valid-road[
      set result false
      ]
    ]
  ]
  report result
end




to setup-turtles
   set RVPoints 1
   create-player1 1
  [
    set shape "house"
    set color red
    setxy redXstart redYstart ;starting position
  ]
end


to setup-patches
  resize-world (-1 - boardSize) (boardSize + 1) (-1 - boardSize) (boardSize + 1) ;resize world depending on map size
  ask patches [
    let y (boardSize - 1)
    if ((not (pxcor mod 2 = 0)) or (not (pycor mod 2 = 0))) [set pcolor 1]
    if (((pxcor > (boardSize - 1)) or (pxcor < (1 - boardSize)))
      or ((pycor > (boardSize - 1)) or (pycor < (1 - boardSize)))) [ set pcolor sky]
    foreach range (boardSize) [
    i ->
      create-row y
      set y (y - 2)
    ]
    fix-tile-value ; 7 tileValue should only be for desert tiles
    create-fixed-starting-resource
  ]
end


; finds all resources with a 7 tile value and gives it a new non-7 tileValue
to fix-tile-value
  if ((tileValue = 7) and (pcolor != brown) and ((pcolor != 1) or (pcolor != sky))) [
     let addorsub random 2
     let randnum random 3 + 1
      (ifelse
        addorsub = 0 [
          (set tileValue (tileValue + randnum))
        ]
        addorsub = 1 [
          (set tileValue (tileValue - randnum))
        ])
    ]
end


to create-fixed-starting-resource
  let startValue 4
  if ((pxcor = -2) and (pycor = 2))  [ set pcolor green set tileValue startValue]
  if ((pxcor = -2) and (pycor = 0))  [ set pcolor orange set tileValue startValue]
  if ((pxcor = 0) and (pycor = 2))  [ set pcolor yellow set tileValue startValue]
  if ((pxcor = 0) and (pycor = 0))  [ set pcolor white set tileValue startValue]
end


; determines distribution of resources in the map using percentage as probability
to create-row [y]
  let x (boardSize - 1)
  foreach range (boardSize) [
    i ->
    let randColor random 100
    let randTile random 6 + random 6
    (ifelse
    randColor < woodProbability [ ;wood
      if ((pxcor = x) and (pycor = y))  [ set pcolor green set tileValue randTile]
    ]
    ((randColor >= woodProbability) and (randColor < (woodProbability + brickProbability))) [ ;brick
      if ((pxcor = x) and (pycor = y))  [ set pcolor orange set tileValue randTile]
    ]
    ((randColor >= (woodProbability + brickProbability)) and
     (randColor < (woodProbability + brickProbability + wheatProbability))) [ ;wheat
      if ((pxcor = x) and (pycor = y))  [ set pcolor yellow set tileValue randTile]
    ]
    ((randColor >= (woodProbability + brickProbability + wheatProbability)) and ;sheep
     (randColor < (woodProbability + brickProbability + wheatProbability + sheepProbability))) [
      if ((pxcor = x) and (pycor = y))  [ set pcolor white set tileValue randTile]
    ]
    (randColor >= (woodProbability + brickProbability + wheatProbability + sheepProbability)) [
      if ((pxcor = x) and (pycor = y))  [ set pcolor brown set tileValue 7] ;desert
    ])
    set x (x - 2)
    ]
end





@#$#@#$#@
GRAPHICS-WINDOW
411
17
975
582
-1
-1
26.5
1
10
1
1
1
0
1
1
1
-10
10
-10
10
0
0
1
ticks
30.0

BUTTON
48
19
111
52
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
123
19
186
52
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
8
163
58
208
Rwood
rWood
17
1
11

MONITOR
62
163
112
208
Rbrick
rBrick
17
1
11

MONITOR
117
163
167
208
Rwheat
rWheat
17
1
11

MONITOR
172
164
229
209
Rsheep
rSheep
17
1
11

MONITOR
234
164
312
209
R Vic-points
rVPoints
17
1
11

SWITCH
14
363
166
396
show-value?
show-value?
0
1
-1000

CHOOSER
152
82
290
127
boardSize
boardSize
9 11
0

INPUTBOX
18
76
77
136
redXstart
-1.0
1
0
Number

INPUTBOX
76
76
136
136
redYstart
1.0
1
0
Number

SLIDER
195
319
367
352
woodProbability
woodProbability
0
100 - (desertProbability + brickProbability + wheatProbability + sheepProbability)
23.0
1
1
NIL
HORIZONTAL

SLIDER
195
351
367
384
brickProbability
brickProbability
0
100 - (desertProbability + woodProbability + wheatProbability + sheepProbability)
23.0
1
1
NIL
HORIZONTAL

SLIDER
195
383
367
416
wheatProbability
wheatProbability
0
100 - (desertProbability + brickProbability + woodProbability + sheepProbability)
23.0
1
1
NIL
HORIZONTAL

SLIDER
195
415
367
448
sheepProbability
sheepProbability
0
100 - (desertProbability + brickProbability + wheatProbability + woodProbability)
23.0
1
1
NIL
HORIZONTAL

SLIDER
195
447
367
480
desertProbability
desertProbability
0
100 - (brickProbability + wheatProbability + woodProbability + sheepProbability)
8.0
1
1
NIL
HORIZONTAL

INPUTBOX
9
230
81
290
woodWeight
0.1
1
0
Number

INPUTBOX
84
230
153
290
brickWeight
0.1
1
0
Number

INPUTBOX
155
230
227
290
wheatWeight
0.1
1
0
Number

INPUTBOX
230
230
305
290
sheepWeight
0.1
1
0
Number

INPUTBOX
312
231
375
291
distWeight
0.1
1
0
Number

SWITCH
13
328
166
361
show-details?
show-details?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

A basic implementation of the board game Settlers of Catan in a square grid. The agent chooses which where to build its next settlement based on weights that are provided. It rates the settlement positions based on the amount and types of resources it provides and the distance to reach that position.


## HOW IT WORKS

Each turn two random dice are rolled, going from 0-5. The sums of their values allow the tiles with those labels to produce 1 resource to adjacent settlements. 

The agent scans the board and chooses the best next position to build a settlement on. When it has the resources to do so, it will build a road toward that goal, or build a settlement if it would build on that goal.

Green tiles produce Wood
Orange tiles produce Brick
Yellow tiles produce Wheat
White tiles produce Sheep

A road costs 1 Wood and 1 Brick
A settlement costs 1 of each resource

The first settlement always spawns with one of each resource beside it to avoid deadlock

## HOW TO USE IT

Click setup to create a random boad state. Click go to advance each turn or set it to run forever to see it quickly cover the board.

The probability sliders affect the initial setup. You can change how likely each resource is to spawn to see different behaviours

Enter different weights to adjust what the agent prioritizes (higher values means it cares more about this)

You can adjust the board size to try the modal with different sizes

The show-display toggle displays the Roll number for each resource tile

The show-detail toggle causes the model to display more detail about the turn to the console

## THINGS TO NOTICE

The agent will build very slowly to begin with, but can quite quickly expload in action after getting a few settlements down. Different parameters will cause it to achieve this growth faster or slower depending on what it values.

The Wood, Brick, and Distance parameters are particularly important, a very low distance will cause it to seek out the highest-producing tiles.

## THINGS TO TRY

Try playing with high and low distance weights to see it cross the map to get another resource.
Try putting in negative values to cause it to avoid tiles of a certain type.
You can also change the setup to make certain resouces scare, then change how much the model values that resource.

## EXTENDING THE MODEL

An extension could be to change build costs of roads and settlements, such as making it cost more wood and brick to build a road, or that a settlement might need 5 Sheep and 1 of everything else.

## NETLOGO FEATURES

Netlogo doesn't have built in path-finding abilities, so to find the nearest building point to a goal we used direct distance and found the nearest valid buildable tile.



@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment1" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>rVPoints</metric>
    <enumeratedValueSet variable="sheepProbability">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desertProbability">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="redYstart">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boardSize">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="redXstart">
      <value value="-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brickProbability">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-value?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wheatProbability">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="woodProbability">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="blueYstart">
      <value value="-7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="blueXstart">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment2" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>rVPoints</metric>
    <enumeratedValueSet variable="boardSize">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="redYstart">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sheepWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desertProbability">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brickWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="redXstart">
      <value value="-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="woodProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="woodWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sheepProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brickProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wheatWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-value?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wheatProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="blueYstart">
      <value value="-7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="blueXstart">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment3" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>rVPoints</metric>
    <enumeratedValueSet variable="desertProbability">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sheepWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="redYstart">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brickWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="redXstart">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boardSize">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="woodProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="woodWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sheepProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brickProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wheatWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-value?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wheatProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="blueYstart">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="blueXstart">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment4" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>rVPoints</metric>
    <enumeratedValueSet variable="woodWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brickWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wheatWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sheepWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distWeight">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="woodProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brickProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desertProbability">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wheatProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sheepProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="redYstart">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boardSize">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="redXstart">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-details?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-value?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
