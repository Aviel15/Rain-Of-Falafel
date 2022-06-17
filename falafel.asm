include mymacro.asm
IDEAL
MODEL small
STACK 100h
DATASEG
	x		dw	?	        	   	     ; column
	y		dw	?		 		     	 ; line
	color	db  ?						 ; color
	len 	dw	?						 ; length of horizontal line
	num		dw	?		                 ; number of lines
	;bmp
    player  db 'player.bmp',0            ;player left side
	player2  db 'player2.bmp',0          ;player right side
	backgroud db 'White.bmp',0           ;background of player
	backgroudF db 'White1.bmp',0         ;background of falafel
	startgame   db 'start.bmp',0         ;start screen bmp
	falafel db 'falafel.bmp',0           ;falafel bmp
	hamburger      db 'burger.bmp',0     ;hamburger bmp
	tomato         db 'tomato.bmp',0     ;tomato bmp
	instructions   db 'instru1.bmp',0    ;instruction screen bmp
	EndScreen db 'end3.bmp',0            ;end screen bmp
	counter   db 'counter1.bmp',0        ;show counter
    filehandle dw ?                      ;use to save and understand the bmp file            
    Header   db 54 dup (0)               ;read size of bmp
    Palette  db 256*4 dup (0)            ;read color of bmp        
    ScrLine  dw 320 dup (0)              ;the place that can print the bmp
	leftGap  dw 0                        ;position x of screens (instruction, start, end)
	topGap   dw 0*320                    ;position y of screens (instruction, start, end)
	picHigh  dw 200                      ;the size of screens (instruction, start, end) 
	picWidth dw 320                      ;the size of screens (instruction, start, end) 
	
	FleftGap  dw 50                      ;the position of falafel
	FtopGap   dw 0*320                   ;the position of falafel
	FpicHigh  dw 20                      ;the size of falafel
	FpicWidth dw 20                      ;the size of falafel
	moveAgain db 0                       ;check if continue drop the falafel
	side db 1                            ;side 1 - left, side 0 - right
	maxPos  dw 0                         ;use to pass a value between registers
	
	Clock 	  	equ es:6Ch               ;clock 
	delayTime	dw 10                    ;make a delay between every drop falafel
	
	gameOver	db 0		             ;0=continue, 1=end
	
	randNum		dw ?		             ;random number
	seed		dw 0		             ;place in the code segment
	checkTomato db ?                     ;check if print tomato bmp
	
	score		db 0			    	 ;score of falafel
	scoreH		db 0			    	 ;score of hamburger
	scoreT      db 0                     ;score of tomato
	divisorTable	db	10,1,0           ;use to div&mod (at this code to random number)
	speedOfFalafel  dw 6400              ;the speed of falafel drop
	speedOfObstacleLow dw 6400           ;the speed if he close to player
	speedOfPlayer   dw 4                 ;the speed of falafel drop
	counterForSound dw 0                 ;run for make delay
	counterForSound2 dw 0                ;run for make delay
	counterForSound3 dw 0                ;run for make delay
	counterForSound4 dw 0                ;run for make delay
	tomatoActive     db 0                ;check if tomato on screen
	
	note dw 3043h                        ;kind of voice 
CODESEG
	include "procs.asm"
	
start:
	mov ax, @data
	mov ds, ax
	
	; set es to clock area
	mov ax, 40h
	mov es, ax
; --------------------------
	; Graphic mode
	mov ax, 13h 
	int 10h

	
	;Draw start screen
StartGameAgain:
	mov [score], 0
	mov [scoreH], 0
	mov al,[score]

	mov [speedOfFalafel], 6400    ;start speed 6400/320=20
	mov [speedOfPlayer], 4        ;start speed of player
	mov dx, offset startgame
    call printPic
CheckAgain:
;waiting to see if the pressed enter or esc
	mov ah,00h
	int 16h
	cmp al, 27         ;check if press ESC
	jne checkR         ;if equal jump exit from game
	jmp EndGame
checkR:
	cmp al, 114        ;check if press R
	jne checkEnter     ;if equal print instructions screen
	mov dx, offset instructions
	call printPic
checkEnter:
	cmp al, 13         ;check if press ENTER 
	jne CheckAgain	   ;if equal jump to start the game

BackGround:
	;Draw ground
	mov [x], 0         ;start column    
	mov [y], 160	   ;start line
	mov [color], 2     ;color green
	mov [len], 320     ;length at each line
	mov [num], 40      ;numbers of line
	call drawSquare
	; draw textbox
	mov [x], 101      ;start column    
	mov [y], 180	  ;start line
	mov [color], 0    ;color green
	mov [len], 20     ;length at each line
	mov [num], 16     ;numbers of line
	call drawSquare
	;draw counter
	mov al,[score]
	mov  dl, 13   ;Column
	mov  dh, 23   ;Row
	mov  bh, 0h   ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h
	call printNumber
	;Process BMP file
	mov [ScrLine], 60
	mov [leftGap], 38
	mov [topGap], 174*320
	mov [picHigh], 24
	mov [picWidth], 60
	mov dx, offset counter
	call printPic
	;Draw background
	mov [x], 0         ;start column
	mov [y], 0         ;start line
	mov [color],0ffh   ;color white
	mov [len], 320     ;length at each line
	mov [num], 160     ;numbers of line
	call drawSquare
	;Draw player
	mov [leftGap], 146
	mov [topGap], 109*320
	mov [picHigh], 50
	mov [picWidth], 28
	mov dx, offset player
	call printPic
	
	call random    ;check which obstacle will print
	
	
	;move player
	mov si, [Clock]		; take first tick
wait1:
	; check if timer change
	cmp si,[Clock]
	je goahead
	mov si, [Clock]
	sub [delayTime],1
	jnz goahead
	mov [delayTime],10
	cmp [moveAgain], 1
	je notMove
	
	cmp [checkTomato], 1      ;check if drop hamburger
	jne printFalafelBall
	call moveTomato
	jmp notMove
	
printFalafelBall:
	call moveFlafel
notMove:
	cmp [gameOver],1          ;if he touch at the ground the game over      
	jne goahead
	mov [gameover],0          ;set 0 for if start game again the proc run
	jmp EndGame
goahead:
	cmp [moveAgain],1         ;check catch 1 - there is catch 0 - there is not catch   
	jne goahead1
	cmp [side], 1
	jne playerPrint
	mov dx, offset player    ;print left side
	jmp jumpPrint
playerPrint:
	mov dx, offset player2   ;print right side
jumpPrint:
	call printPic
	
	call notePlay  		;play a sound when catch the falafel
	mov [moveAgain],0
	cmp [checkTomato], 0
	jne speedSame
	add [speedOfFalafel], 320
speedSame:
	mov al,[score]

	mov  dl, 13   ;Column
	mov  dh, 23   ;Row
	mov  bh, 0h   ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h
	
	call printNumber
	
	call random
	
	jmp wait1
goahead1:
	;checking by the ports:
	in al, 64h 		; reading keyboard status port
	cmp al, 10b 	;checking if there is new scane code
	jne cont2 		;waiting until there is new scane code
	jmp wait1
cont2:
	in al, 60h 		;getting keyboard data
	mov ah,0bh
	int 21h
	cmp al,0
	jne CheckESC
	jmp RightArrow
CheckESC:
	mov ah,7h
	int 21h
	cmp al, 27		;ESC
	jne RightArrow
	jmp EndGame		; esc
RightArrow:
	;check if it's right arrow
	cmp al, 4Dh
	jne leftArrow
	;checking the ratio between the character and the walls:
	mov ax, 320-28  ;the width of player
	sub ax, [speedOfPlayer]    ;the next position
	cmp [leftGap], ax
	jbe moveRight              ;if below or equal he can keep move
	jmp wait1
moveRight:
	;print the character in another place and paint the background:
	mov [side], 0
	mov [picHigh], 50
	mov [picWidth], 28
	mov dx, offset backgroud
	call printPic  ;print the picture
	pop ax
	mov ax, [speedOfPlayer]
	add [leftGap], ax
	push ax
	mov [picHigh], 50
	mov [picWidth], 28
	mov dx, offset player2
	call printPic  ;print the picture
	jmp wait1
leftArrow:
	cmp al, 4Bh
	je Continue
	jmp wait1
Continue:
	;check if hit the wall
	mov ax, [speedOfPlayer]      ;the speed in next positon, ax start from "0" because it is the left side and here we add the next position and not let down him
	cmp [leftGap], ax
	jae moveLeft
	jmp wait1
moveLeft:
	mov [side], 1
	;print the character in another place and paint the background:
	mov [picHigh], 50
	mov [picWidth], 28
	mov dx, offset backgroud
	call printPic         ;print the picture
	pop ax
	mov ax, [speedOfPlayer]
	sub [leftGap], ax
	push ax
	mov [picHigh], 50
	mov [picWidth], 28
	mov dx, offset player 
	call printPic         ;print the picture
	mov cx, [leftGap]
	jmp wait1

EndGame:
	call notePlay  		;play a sound when game over
	mov [ScrLine], 320 
	mov [leftGap], 0
	mov [topGap], 0*320
	mov [picHigh], 200
	mov [picWidth], 320
	mov dx, offset EndScreen
	call printPic
	
	; draw textbox
	mov [x], 182      ;start column    
	mov [y], 180 	  ;start line
	mov [color], 0    ;color green
	mov [len], 20     ;length at each line
	mov [num], 16     ;numbers of line
	call drawSquare
	
	mov  dl, 23   ;Column
	mov  dh, 23   ;Row
	mov  bh, 0h   ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h
	mov al,[score]
	call printNumber
	
finshing:	
	mov ah,00h
	int 16h
	cmp al, 27         ;check if press ESC
	je EndGame1        ;if equal jump exit from game
	cmp al, 13         ;check if press ENTER 
	je again 		   ;if equal jump to start the game
	jne finshing
again:
	jmp StartGameAgain
EndGame1: 
	
	; Back to text mode
	mov ah, 0
	mov al, 2
	int 10h
exit:
	mov ax, 4c00h
	int 21h
END start