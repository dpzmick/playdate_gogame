sources = source/main.lua source/engine.lua source/util.lua
assets =

all: GoGame.pdx

GoGame.pdx: $(sources) $(assets)
	pdc source GoGame.pdx

run: GoGame.pdx
	open GoGame.pdx

test: $(sources) source/test.lua
	cd source && lua test.lua
