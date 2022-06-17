; receives: list of registers
; pushing the given registers
doPush macro r1,r2,r3,r4,r5,r6,r7,r8,r9
        irp register,<r9,r8,r7,r6,r5,r4,r3,r2,r1>
                ifnb <register>
                        push register
                endif
        endm
endm

; receives: list of registers
; popping the given registers
doPop macro r1,r2,r3,r4,r5,r6,r7,r8,r9
        irp register,<r9,r8,r7,r6,r5,r4,r3,r2,r1>
                ifnb <register>
                        pop register
                endif
        endm
endm

openSpeaker macro
; open speaker
in al,61h
or al,00000011b
out 61h,al
endm

closeSpeaker macro
; close the speaker
in al,61h
and al,11111100b
out 61h,al
endm