sources = source/main.lua
assets = source/images/blackStone.png

all: GoGame.pdx

GoGame.pdx: $(sources) $(assets)
	pdc source GoGame.pdx

run: GoGame.pdx
	open GoGame.pdx
