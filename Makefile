#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

include $(DEVKITARM)/ds_rules

#---------------------------------------------------------------------------------
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# DATA is a list of directories containing data files
# INCLUDES is a list of directories containing header files
# SPECS is the directory containing the important build and link files
#---------------------------------------------------------------------------------
export TARGET	:=	Hourglass9
BUILD		:=	build
SOURCES		:=	source source/fatfs source/decryptor
DATA		:=	data
INCLUDES	:=	source source/fatfs

#---------------------------------------------------------------------------------
# THEME: if set to anything, name of the themes file folder inside resources
#---------------------------------------------------------------------------------
THEME	:=	

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
ARCH	:=	-mthumb -mthumb-interwork -flto

CFLAGS	:=	-g -Wall -Wextra -Wpedantic -pedantic -O2\
			-march=armv5te -mtune=arm946e-s -fomit-frame-pointer\
			-ffast-math -std=c99\
			$(ARCH)

CFLAGS	+=	$(INCLUDE) -DEXEC_$(EXEC_METHOD) -DARM9 -D_GNU_SOURCE

CFLAGS	+=	-DBUILD_NAME="\"$(TARGET) (`date +'%Y/%m/%d'`)\""

ifneq ($(strip $(THEME)),)
CFLAGS	+=	-DUSE_THEME=\"\/$(THEME)\"
endif

CXXFLAGS	:= $(CFLAGS) -fno-rtti -fno-exceptions

ASFLAGS	:=	-g $(ARCH) -DEXEC_$(EXEC_METHOD)
LDFLAGS	=	-nostartfiles -g $(ARCH) --specs=../stub.specs -Wl,-Map,$(TARGET).map

LIBS	:=

#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS	:=

#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT_D	:=	$(CURDIR)/output
export OUTPUT	:=	$(OUTPUT_D)/$(TARGET)
export RELEASE	:=	$(CURDIR)/release

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
			$(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
BINFILES	:=	$(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

#---------------------------------------------------------------------------------
# use CXX for linking C++ projects, CC for standard C
#---------------------------------------------------------------------------------
ifeq ($(strip $(CPPFILES)),)
#---------------------------------------------------------------------------------
	export LD	:=	$(CC)
#---------------------------------------------------------------------------------
else
#---------------------------------------------------------------------------------
	export LD	:=	$(CXX)
#---------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------

export OFILES	:= $(addsuffix .o,$(BINFILES)) \
			$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
			$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
			-I$(CURDIR)/$(BUILD)

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib)

.PHONY: common clean all a9lh release

#---------------------------------------------------------------------------------
all: a9lh

common:
	@[ -d $(OUTPUT_D) ] || mkdir -p $(OUTPUT_D)
	@[ -d $(BUILD) ] || mkdir -p $(BUILD)

a9lh: common
	@make --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile
	
release: a9lh
	@[ -d $(RELEASE) ] || mkdir -p $(RELEASE)
	@cp $(OUTPUT).bin $(RELEASE)
	@cp $(CURDIR)/README.md $(RELEASE)
	@-[ ! -n "$(strip $(THEME))" ] || (mkdir $(RELEASE)/$(THEME) && cp $(CURDIR)/resources/$(THEME)/*.bin $(RELEASE)/$(THEME))
	@-7z a $(RELEASE)/$(TARGET)-`date +'%Y%m%d-%H%M%S'`.zip $(RELEASE)/*
	
#---------------------------------------------------------------------------------
clean:
	@echo clean ...
	@rm -fr $(BUILD) $(OUTPUT_D) $(RELEASE)


#---------------------------------------------------------------------------------
else

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
$(OUTPUT).bin	:	$(OUTPUT).elf
$(OUTPUT).elf	:	$(OFILES)


#---------------------------------------------------------------------------------
%.bin: %.elf
	@$(OBJCOPY) --set-section-flags .bss=alloc,load,contents -O binary $< $@
	@echo built ... $(notdir $@)

#---------------------------------------------------------------------------------
# you need a rule like this for each extension you use as binary data
#---------------------------------------------------------------------------------
#---------------------------------------------------------------------------------
bottomlogo.bgr.o: bottomlogo.bgr
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

-include $(DEPENDS)


#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------
