@ECHO OFF
ECHO Make the pong game
ECHO ON

PATH = c:\16bitx86\NASM\bin;c:\16bitx86\NASM\NASMIDE;c:\16bitx86\tc\bin;c:\16bitx86\util;%PATH%

nasm -f obj beginCOM.asm
nasm -f obj endCOM.asm

nasm -f obj main.asm
nasm -f obj timer.asm
nasm -f obj pixel.asm
nasm -f obj screen.asm
nasm -f obj paddle.asm
nasm -f obj keyboard.asm
nasm -f obj block.asm
nasm -f obj composte.asm
nasm -f obj pause.asm
nasm -f obj ball.asm
nasm -f obj score.asm
nasm -f obj sound.asm

tlink  /m /s /d beginCOM main timer screen paddle pixel keyboard block composte pause ball score sound endCOM , main , main , ,


chop512 main
copy main.bin pong.com
pause
