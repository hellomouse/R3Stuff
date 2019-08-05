game:
    .map: ;bit 0      -> is opened
          ;bit 1      -> is mine
          ;bit 2      -> has mine neighbor (precalculated)
          ;bit [3, 5] -> mine count (precalculated)
        org { game.map 256 + }
    .minesleft:
        dw 0
    .time:
        dw 

;original game:
;Beginner     - 9*9   @ 10 (.12)
;Intermediate - 16*16 @ 40 (.15)
;Advanced     - 24*24 @ 99 (.17)