; enter - x- column, y-line, color
; exit - print pixel in color at x,y
proc drawPixel
	doPush ax,bx,cx,dx
	xor bh,bh      ;bh = 0
	mov cx,[x]     ;save the value in operands
	mov dx,[y]
	mov al,[color]
	mov ah,0ch     ;Interrput code
	int 10h
	doPop dx,cx,bx,ax
	ret
endp drawPixel

; enter - x- column, y-line, color, len - length
; exit - print pixel in color at x,y
proc drawLine
	push cx
	mov cx,[len]
pixel:
	call drawPixel
	inc [x]       ;x=x+1
	loop pixel
	pop cx
	ret
endp drawLine

; enter - x- column, y-line, color, len - length, num - numbers of line
; exit - print pixel in color at x,y
proc drawSquare
	doPush cx,ax
	mov ax,[x]		; keep start of line
	mov cx,[num]
line:
	call drawLine
	mov [x],ax		; return to start of line
	inc [y]
	loop line
	doPop ax,cx
	ret
endp drawSquare


;enter – file name in filename
;exit - Open file, put handle in filehandle
proc OpenFile 
	mov ah, 3Dh
	xor al, al       ;al = 0
	int 21h
	mov [filehandle], ax       ;save in filehandle
	ret
endp OpenFile

;enter - get filehandle
;exit - read header
proc ReadHeader
; Read BMP file header, 54 bytes
    mov ah,3fh
    mov bx, [filehandle]     
    mov cx , 54        ;number of bytes
    mov dx,offset Header    
    int 21h 
    ret
endp ReadHeader

;enter - get filehandle
;exit - read color palette
proc ReadPalette
; Read BMP file color palette, 256 ; colors * 4 bytes (400h)
    mov ah,3fh
    mov bx, [filehandle]
    mov cx , 400h 
    mov dx,offset Palette
    int 21h 
    ret
endp ReadPalette

;enter - get offset palette
;exit - Copy the colors palette to the video memory registers 
proc CopyPal
	push si
; The number of the first color should be sent to port 3C8h
; The palette is sent to port 3C9h
	mov si,offset Palette 
	mov cx,256 
	mov dx,3C8h
	mov al,0 
	; Copy starting color to port 3C8h
	out dx,al
	; Copy palette itself to port 3C9h
	inc dx 
PalLoop:
; Note: Colors in a BMP file are saved as BGR values rather than RGB.
	mov al,[si+2] 	; Get red value.
	shr al,2 		; Max. is 255, but video palette maximal
 ; value is 63. Therefore dividing by 4.
	out dx,al		 ; Send it.
	mov al,[si+1] 	; Get green value.
	shr al,2
	out dx,al 		; Send it.
	mov al,[si] 	; Get blue value.
	shr al,2
	out dx,al 		; Send it.
	add si,4		 ; Point to next color.
 ; (There is a null chr. after every color.)
	loop PalLoop
	pop si
	ret
endp CopyPal

;enter - get scrLine
;exit - displaying the lines from bottom to top
proc CopyBitmap
; BMP graphics are saved upside-down.
; Read the graphic line by line (200 lines in VGA format),
	doPush si,es
	mov ax, 0A000h
	mov es, ax
	mov cx,[picHigh] 
	PrintBMPLoop:
	push cx
; di = cx*320, point to the correct screen line
	mov di,cx 
	shl cx,6 
	shl di,8 
	add di,cx
    add di,[leftGap]
    add di,[topGap]
	; Read one line
	mov ah,3fh
	mov cx,[picWidth]
	mov dx,offset ScrLine
	int 21h 
; Copy one line into video memory
	cld 		; Clear direction flag, for movsb
	mov cx,[picWidth]
	mov si,offset ScrLine
	rep movsb 	; Copy line to the screen
	pop cx
	loop PrintBMPLoop
	doPop es,si
	ret
endp CopyBitmap

;enter – get filehandle
;exit – close the bmp file
proc CloseFile
	mov ah,3Eh
	mov bx, [filehandle]
	int 21h
	ret
endp CloseFile

;enter - None
;exit - call to procs to save lines
proc printPic
    call OpenFile
    call ReadHeader
    call ReadPalette
    call CopyPal
    call CopyBitmap
    call CloseFile
	ret
endp printPic

;enter - get the place postions
;exit - update to new position
proc printFlafel
	doPush [leftGap],[topGap],[picHigh],[picWidth],ax
	; Process BMP file
	mov ax,[FleftGap]      
	mov [leftGap], ax   ;update the x position
	mov ax,[FtopGap]
	mov [topGap], ax    ;update the y position
	mov [picHigh], 20
	mov [picWidth], 20
	call printPic

	doPop ax,[picWidth],[picHigh],[topGap],[leftGap]
ret
endp printFlafel

;enter - get the place and speed of the obstacle
;exit - check if the player don't catch the obstacle and if not he will drop obstacle
proc moveFlafel
	doPush bx,dx,cx,ax
	;checking the ratio between the character and the walls:
	cmp [FtopGap], 140*320 ;ground - 140 but the height of falafel or hamburger is 20
	jna goDown          ;smaller than ground place
	mov [gameOver],1    ;if he touch at the ground the game over
	jmp retmovFalafel
goDown:
	; check if hit the person
	mov dx, [FtopGap]   
	add dx, 2*20*320    ;because the point is from the top of the falafel so we take down to check from the bottom
	cmp dx, 112*320     ;120 is possible height that the person can catch him
	jb contmov          ;continue the fall the falafel not in place that the player possible catch him
	mov dx, [FleftGap]  
	cmp dx, [leftGap]	;compare
	jb checkLeftSide    ;if below, check if the falafel on the left side of player
	; player left to falafel
	mov dx, [leftGap]
	add dx, 28          ;the height of player
	cmp dx, [FleftGap]
	jb contmov
	;catch
	;add count
	;disappear falafel

	mov dx, offset backgroudF
	call printFlafel   ;print the background
	mov [moveAgain], 1 ;catch and stop drop the falafel
	inc [scoreH]
	inc [score]
	jmp retmovFalafel   
checkLeftSide:
	add dx,20          ;the width of falafel
	cmp dx ,[leftGap]  ;compare
	jb contmov	       ;continue the fall if the player don't touch the falafel
	;catch
	;add count
	;disappear falafel
	mov dx, offset backgroudF
	call printFlafel   ;print the picture
	mov [moveAgain], 1 ;catch and stop drop the falafel
	inc [scoreH]
	inc [score]        ;increase every catch
	jmp retmovFalafel
contmov:
	;print the character in another place and paint the background:
	mov dx, offset backgroudF
	call printFlafel           ;print the background on falafel
NotChange:
	mov ax, [speedOfFalafel]
	add [FtopGap], ax
	
	cmp [scoreH], 10           ;check if score is round number
	jne drawFalafel
	;print tomato
	mov dx, offset hamburger
	jmp draw
drawFalafel:
	;print falafel
	mov dx, offset falafel
draw:
	call printFlafel  ;print the picture
retmovFalafel:
	doPop ax,cx,dx,bx, 
	ret
endp moveFlafel

;enter - get the place and speed of the obstacle
;exit - check if the player don't catch the obstacle and if not he will drop obstacle
proc moveTomato
	doPush dx,cx
	;checking the ratio between the character and the walls:
	cmp [FtopGap], 140*320 ;ground - 140 but the height of falafel or hamburger is 20
	ja smallerGround         ;smaller than ground place
	jmp goDownT
smallerGround:
	mov dx, offset backgroudF
	call printFlafel
	mov [moveAgain], 1 ;catch and stop drop the falafel
	
	;Draw ground
	mov [x], 0         ;start column    
	mov [y], 160	   ;start line
	mov [color], 2     ;color green
	mov [len], 320     ;length at each line
	mov [num], 20      ;numbers of line
	call drawSquare
	
	jmp retmovFalafelT
goDownT:
	; check if hit the person
	mov dx, [FtopGap]   
	add dx, 2*20*320    ;because the point is from the top of the tomato so we take down to check from the bottom
	cmp dx, 112*320     ;120 is possible height that the person can catch him
	jb contmovT         ;continue the fall the tomato not in place that the player possible catch him
	mov dx, [FleftGap]  
	cmp dx, [leftGap]	;compare
	jb checkLeftSideT    ;if below, check if the tomato on the left side of player
	; player left to tomato
	mov dx, [leftGap]
	add dx, 28
	cmp dx, [FleftGap]
	jb contmovT
	;catch
	;disappear tomato
	jmp EndGame
	
checkLeftSideT:
	add dx,20          ;the width of tomato
	cmp dx ,[leftGap]  ;compare
	jb contmovT	       ;continue the fall if the player don't touch the tomato
	;catch
	;disappear tomato
	jmp EndGame
	
contmovT:
	;print the character in another place and paint the background:
	mov dx, offset backgroudF
	call printFlafel ;print the picture
	mov ax, [speedOfFalafel]
	add [FtopGap], ax
	mov dx, offset tomato
	call printFlafel  ;print the picture
	
retmovFalafelT:
	doPop cx,dx
	ret
endp moveTomato

;enter - get 3 kinds of obstacles
;exit - check which obstacle
proc random
	mov [tomatoActive], 0
	call rndplace             ;random place between 5-293
	mov ax, [randNum]         ;save in ax  
	mov [FleftGap], ax        ;the place is the random number 
	mov [FtopGap], 0		  ;start from first line
	cmp [scoreH], 10
	jne CheckT
	mov dx, offset hamburger  ;print falafel in the random number
	call printFlafel
	jmp exit1
CheckT:
	call DropTomato        
	cmp [checkTomato], 1      ;check if will print tomato
	jne PrintF1           
	mov [tomatoActive], 1
	mov dx, offset tomato
	call printFlafel
	jmp exit1	
PrintF1:
	mov dx, offset falafel    ;print falafel in the random number
	call printFlafel
exit1:
	ret
endp random

; enter - None
; exit - number between 5-293 
proc rndplace

	doPush ax,es,bx
	; initialize
	mov ax, 40h
	mov es, ax

	mov bx, [seed]    

	; generate random number, cx number of times
	mov ax, [Clock] 		; read timer counter
	mov ah, [byte cs:bx] 	; read one byte from memory
	inc [seed]				; increase for next time
	xor al, ah 			    ; xor memory and counter
	mov bl, al
	and al, 11111111b 		; leave result between 0-255
	and bl, 00011111b		; leave result between 0-31 
	
	; build the number in word
	xor ah,ah
	xor bh,bh
	add ax,bx
	; add 5 to start not from 0
	add ax,5
	mov [randNum],ax
	
	doPop bx,es,ax
ret

endp rndplace

;enter - random place
;exit - if random number divide by 5 will drop tomato
proc DropTomato
	doPush ax,bx
	mov [checkTomato], 0  ;at start he will not be print
	call rndplace         ;random number
	mov bl, 5           
	mov ax, [randNum]
	div bl                ;divide by 5
	cmp ah, 0             
	jne retDropTomato 
	mov [checkTomato], 1  ;if divide by 5 will print the tomato
retDropTomato:
	doPop bx,ax
	ret
endp DropTomato

; enter – number in al
; exit – printing the numbers digit by digit
proc 	printNumber
   	doPush 	ax,bx,dx
	mov  bx, offset divisorTable
nextDigit:
    xor 	ah,ah         		
    div 	[byte ptr bx]   	;al = quotient, ah = remainder
    add 	al,'0'
    call 	printCharacter  	;Display the quotient
    mov 	al,ah          		;ah = remainder
	add 	bx,1                ;bx = address of next divisor
    cmp 	[byte ptr bx],0 	;Have all divisors been done?
    jne 	nextDigit
   	doPop 	dx,bx,ax
	ret
endp 	printNumber

; enter – character in al
; exit – printing the character
proc 	printCharacter
	doPush	ax,dx
	mov	dl, al
	mov	ah,2
	int	21h
	
	doPop	dx,ax
	ret
endp	printCharacter

;enter - the note of the specific location
;exit -  a note is played
proc notePlay
	openSpeaker
	; send control word to change frequency
	mov al,0b6h
	out 43h,al
	; play frequency at note
	mov ax, [note]
	out 42h,al ; sending lower byte
	mov al,ah
	out 42h,al ; sending upper byte
	; wait for the key to be unnpressed-
	waiting:
	in al, 60h ; Get keyboard data
	test al,80h
	
delay:
	cmp [counterForSound], 65000
	je endProc
	inc [counterForSound]
	jmp delay
	
endProc:
	mov [counterForSound],0
	closeSpeaker
	ret
endp notePlay