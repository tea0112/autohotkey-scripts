MButton::
old_clip := ClipBoardAll    ; save old clipboard
ClipBoard =                 ; clear current clipboard
send, ^c                    ; selection -> clipboard
ClipWait, 1                 ; retrieve new clipboard
send,{Ctrl down}cc{Ctrl up}