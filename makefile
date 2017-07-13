
#
# current game name
#

GAME=template

GAME_PATH=\
	games\$(GAME)

SRCS=\
	$(GAME_PATH)\$(GAME).asm \
	$(GAME_PATH)\$(GAME).code.asm \
	$(GAME_PATH)\$(GAME).data.asm \
	$(GAME_PATH)\$(GAME).ram.asm

DATAS=\
	$(GAME_PATH)\charset.pcx.chr.$(PACK_EXTENSION) \
	$(GAME_PATH)\charset.pcx.clr.$(PACK_EXTENSION) \
	$(GAME_PATH)\sprites.pcx.spr.$(PACK_EXTENSION) \
	$(GAME_PATH)\screen.tmx.bin.$(PACK_EXTENSION)

DATAS_INTERMEDIATE=\
	$(GAME_PATH)\charset.pcx.chr \
	$(GAME_PATH)\charset.pcx.clr \
	$(GAME_PATH)\sprites.pcx.spr \
	$(GAME_PATH)\screen.tmx.bin

#
# tools
#

ASM=tniasm
EMULATOR=cmd /c start
DEBUGGER=cmd /c start \MSX\bin\blueMSX_2.8.2\blueMSX.exe
PCX2MSX=pcx2msx+
PCX2SPR=pcx2spr
TMX2BIN=tmx2bin

# Uncomment for Pletter 0.5c1
# PACK=pletter
# PACK_EXTENSION=plet5

# Uncomment for ZX7
# (please note that ZX7 does not overwrite output)
PACK=zx7.exe
PACK_EXTENSION=zx7

#
# commands
#

COPY=cmd /c copy
MKDIR=cmd /c mkdir
MOVE=cmd /c move
REMOVE=cmd /c del
RENAME=cmd /c ren

#
# paths and file lists
#
	
TEMPLATE_PATH=\
	games\template

ROM=\
	roms\$(GAME).rom
	
ROM_INTERMEDIATE=\
	$(GAME_PATH)\$(GAME).rom
	
SYM_INTERMEDIATE=\
	$(GAME_PATH)\$(GAME).sym

SRCS_MSXLIB=\
	lib\ram.asm \
	lib\asm.asm \
	lib\msx\symbols.asm \
	lib\msx\cartridge.asm \
	lib\msx\cartridge.ram.asm \
	lib\msx\input.asm \
	lib\msx\input.ram.asm \
	lib\msx\vram.asm \
	lib\msx\vram_msx2.asm \
	lib\msx\vram_x.asm \
	lib\msx\vram.ram.asm \
	lib\game\tiles.asm \
	lib\game\collision.asm \
	lib\game\player.asm \
	lib\game\player_x.asm \
	lib\game\player.ram.asm \
	lib\game\enemy.asm \
	lib\game\enemy_x.asm \
	lib\game\enemy.ram.asm \
	lib\game\bullet.asm \
	lib\game\bullet.ram.asm

SRCS_LIBEXT=\
	libext\pletter05c\pletter05c-unpackRam.tniasm.asm \
	libext\wyzplayer\WYZPROPLAY47cMSX.ASM \
	libext\wyzplayer\WYZPROPLAY47c_RAM.tniasm.ASM \
	libext\zx7\dzx7_standard.tniasm.asm

#
# phony targets
#

# default target
default: compile

clean:
	$(REMOVE) $(ROM_INTERMEDIATE)
	$(REMOVE) $(SYM_INTERMEDIATE) tniasm.sym tniasm.tmp

cleandata:
	$(REMOVE) $(DATAS) $(DATAS_INTERMEDIATE)

cleanall: clean cleandata

compile: $(ROM_INTERMEDIATE)

test: $(ROM_INTERMEDIATE)
	$(EMULATOR) $<

debug: $(ROM_INTERMEDIATE) $(SYM_INTERMEDIATE)
	$(DEBUGGER) $<

deploy: $(ROM)

# secondary targets
.secondary: $(DATAS_INTERMEDIATE)

#
# main targets
#
	
$(GAME_PATH):
	$(MKDIR) $@
	$(COPY) $(TEMPLATE_PATH) $@
	$(RENAME) $(GAME_PATH)\template.asm $(GAME).asm
	
$(ROM_INTERMEDIATE) tniasm.sym: $(GAME_PATH)\$(GAME).asm $(SRCS_MSXLIB) $(SRCS_LIBEXT) $(GFXS) $(SPRS) $(DATAS)
	$(ASM) $< $@
	cmd /c findstr /b /i "bytes_" tniasm.sym | sort

$(SYM_INTERMEDIATE): tniasm.sym
	$(COPY) $< $@

$(ROM): $(ROM_INTERMEDIATE)
	$(COPY) $< $@
	
#
# GFXs targets
#

%.pcx.chr.$(PACK_EXTENSION): %.pcx.chr
	$(REMOVE) $@
	$(PACK) $<

%.pcx.clr.$(PACK_EXTENSION): %.pcx.clr
	$(REMOVE) $@
	$(PACK) $<

%.pcx.nam.$(PACK_EXTENSION): %.pcx.nam
	$(REMOVE) $@
	$(PACK) $<

# -lh by default because packing usally produces smaller binaries
%.pcx.chr %.pcx.clr: %.pcx
	$(PCX2MSX) -lh $<

#
# SPRs targets
#

%.pcx.spr.$(PACK_EXTENSION): %.pcx.spr
	$(REMOVE) $@
	$(PACK) $<

%.pcx.spr: %.pcx
	$(PCX2SPR) $<

#
# BINs targets
#

%.tmx.bin.$(PACK_EXTENSION): %.tmx.bin
	$(REMOVE) $@
	$(PACK) $<

%.tmx.bin: %.tmx
	$(TMX2BIN) $< $@
