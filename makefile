
#
# current game name
#

GAME=template

#
# commands
#

# ASM=asmsx
ASM=tniasm
COPY=cmd /c copy
EMULATOR=cmd /c start
DEBUGGER=cmd /c start \MSX\bin\blueMSX_2.8.2\blueMSX.exe
MKDIR=cmd /c mkdir
MOVE=cmd /c move
REMOVE=cmd /c del
RENAME=cmd /c ren
TYPE=cmd /c type

#
# tools
#

PCX2MSX=pcx2msx+
PCX2SPR=pcx2spr
TMX2BIN=tmx2bin

# Uncomment for Pletter 0.5c1
# PACK=pletter
# PACK_EXTENSION=plet5

# Uncomment for ZX7
PACK=zx7.exe
PACK_EXTENSION=zx7

#
# paths and file lists
#

GAME_PATH=\
	games\$(GAME)
	
TEMPLATE_PATH=\
	games\template

ROM=\
	roms\$(GAME).rom
	
ROM_INTERMEDIATE=\
	$(GAME_PATH)\$(GAME).rom

SRCS_MSXLIB=\
	lib\rom.asm \
	lib\ram.asm \
	lib\asm.asm \
	lib\msx\symbols.asm \
	lib\msx\cartridge.asm \
	lib\msx\input.asm \
	lib\msx\vram.asm \
	lib\game\tiles.asm \
	lib\game\player.asm \
	lib\game\enemy.asm \
	lib\game\enemy_routines.asm \
	lib\game\enemy_handlers.asm \
	lib\extra\spriteables.asm

GFXS=\
	$(GAME_PATH)\charset.pcx.chr.$(PACK_EXTENSION) \
	$(GAME_PATH)\charset.pcx.clr.$(PACK_EXTENSION)

GFXS_INTERMEDIATE=\
	$(GAME_PATH)\charset.pcx.chr \
	$(GAME_PATH)\charset.pcx.clr

SPRS=\
	$(GAME_PATH)\sprites.pcx.spr.$(PACK_EXTENSION)

SPRS_INTERMEDIATE=\
	$(GAME_PATH)\sprites.pcx.spr

DATAS=\
	$(GAME_PATH)\screen.tmx.bin.$(PACK_EXTENSION)

DATAS_INTERMEDIATE=\
	$(GAME_PATH)\screen.tmx.bin

#
# phony targets
#

# default target
default: compile

clean:
	$(REMOVE) tniasm.sym tniasm.tmp
	$(REMOVE) $(GFXS) $(GFXS_INTERMEDIATE)
	$(REMOVE) $(SPRS) $(SPRS_INTERMEDIATE)
	$(REMOVE) $(DATAS) $(DATAS_INTERMEDIATE)

cleanrom:
	$(REMOVE) $(ROM_INTERMEDIATE)

compile: $(ROM_INTERMEDIATE)

test: $(ROM_INTERMEDIATE)
	$(EMULATOR) $<

debug: $(ROM_INTERMEDIATE)
	$(DEBUGGER) $<

deploy: $(ROM)

# secondary targets
.secondary: $(GFXS_INTERMEDIATE) $(SPRS_INTERMEDIATE) $(DATAS_INTERMEDIATE)

#
# main targets
#
	
$(GAME_PATH):
	$(MKDIR) $@
	$(COPY) $(TEMPLATE_PATH) $@
	$(RENAME) $(GAME_PATH)\template.asm $(GAME).asm
	
$(ROM_INTERMEDIATE): $(GAME_PATH)\$(GAME).asm $(SRCS_MSXLIB) $(GFXS) $(SPRS) $(DATAS)
	$(ASM) $< $@
	@findstr /C:"ROM_START"	tniasm.sym
	@findstr /C:"ROM_END"	tniasm.sym
	@findstr /C:"ram_start"	tniasm.sym
	@findstr /C:"ram_end"	tniasm.sym

$(ROM): $(ROM_INTERMEDIATE)
	$(COPY) $< $@
	
#
# GFXs targets
#

%.pcx.chr.$(PACK_EXTENSION): %.pcx.chr
	$(PACK) $<

%.pcx.clr.$(PACK_EXTENSION): %.pcx.clr
	$(PACK) $<

%.pcx.nam.$(PACK_EXTENSION): %.pcx.nam
	$(PACK) $<

# -lh by default as packing produces smaller binaries
%.pcx.chr %.pcx.clr: %.pcx
	$(PCX2MSX) -lh $<

#
# SPRs targets
#

%.pcx.spr.$(PACK_EXTENSION): %.pcx.spr
	$(PACK) $<

%.pcx.spr: %.pcx
	$(PCX2SPR) $<

#
# BINs targets
#

%.tmx.bin.$(PACK_EXTENSION): %.tmx.bin
	$(PACK) $<

%.tmx.bin: %.tmx
	$(TMX2BIN) $< $@
