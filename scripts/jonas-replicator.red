;name Replicator
;description Watch stargate dawg
;author Jonas Hietala

step    EQU 417
init    EQU 1337
size	EQU 9

        JMP start           ; boot jump as we can't specify PC in the middle T.T

src     DAT 0               ; src pointer
start   MOV #size, src       ; setup src pointer
copy    MOV @src, <dst      ; copy self
        DJN copy, src
        SPL @dst            ; throw a pc there

        ADD #step, dst      ; space out a bit
        JMP start           ; make a new copy, yay!

dst     DAT #0, #init       ; dst pointer

end

