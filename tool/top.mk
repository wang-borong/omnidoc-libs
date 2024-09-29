XDG_DATA_DIR := $(HOME)/.local/share
OMNIDOC_LIB  ?= $(XDG_DATA_DIR)/omnidoc

LATEXMK := latexmk
FIGENERATOR := python3 $(OMNIDOC_LIB)/tool/figure-generator.py
BITFIELD := python3 $(OMNIDOC_LIB)/tool/bit-field.py
CONTFORM := perl $(OMNIDOC_LIB)/tool/content-formatter.pl
TOPMAKE  := make -f $(OMNIDOC_LIB)/tool/top.mk
PANDOCMK := $(OMNIDOC_LIB)/tool/pandoc.mk
# set metadata file for pandoc (located in pandoc/data/metadata)
# or eleg-book, eleg-paper, eleg-note
# METADATA_FILE  ?= eleg-book

OUTDIR ?= build
BUILDIR := $(OUTDIR)

ifeq ($(V),)
	TEXOPTS += -quiet
	NOINFO := > /dev/null 2>&1
endif

MAIN ?= $(shell ls main.*)
TEXES := $(shell find . -name "*.tex" | sort)

FIGSRC := $(wildcard drawio/*.drawio)
FIGSRC += $(wildcard dac/*.dot dac/*.mmd)
BFSRC  := $(wildcard dac/*.json)
SVGSRC := $(wildcard figure/*.svg figures/*.svg)

TARGET ?= unknown
TEXOPTS += -jobname=$(TARGET)

export TEXMFHOME=$(OMNIDOC_LIB)/texmf
export TARGET CONTFORM BUILDIR METADATA_FILE XDG_DATA_DIR OMNIDOC_LIB OMNI_PANDOC_OPTS

all: $(BUILDIR) figures
	@if [[ ${MAIN} == "main.md" ]]; then $(TOPMAKE) pandoc; else $(TOPMAKE) latex; fi

latex: $(MAIN)
	@if [[ ! -z $$(ls -A $(FIGSRC) $(SVGSRC) > /dev/null 2>&1) ]]; then $(TOPMAKE) figures; fi
	@$(LATEXMK) $(TEXOPTS) $< || $(LATEXMK) -c $<

pandoc: $(BUILDIR)
	@make -f $(PANDOCMK) V=$(V)

pandoc-tex: $(BUILDIR)
	@make -f $(PANDOCMK) V=$(V) tex

format: $(TEXES)
	@$(CONTFORM) $^
	@make -f $(PANDOCMK) format

figures: $(FIGSRC) $(BFSRC) $(SVGSRC)
	@mkdir -p figures
	@if [[ -n "$(FIGSRC)" ]]; then \
		$(FIGENERATOR) $(FIGSRC); \
	fi
	@for bf in $(BFSRC); do \
		$(BITFIELD) --fontsize=9 $$bf figures/$$(basename $${bf%%.*}).svg; \
	done
	@if [[ -n "$(SVGSRC)" ]]; then \
		$(FIGENERATOR) -c $(SVGSRC); \
	fi

latex-view: latex
	@$(LATEXMK) -f -pvc -view=pdf $(BUILDIR)/$(TARGET) $(NOINFO) &

pandoc-view: pandoc-tex latex
	@$(LATEXMK) -f -pvc -view=pdf $(BUILDIR)/$(TARGET) $(NOINFO) &

kill-view:
	@kill $$(ps aux | grep "latexmk -f -pvc" \
		| head -1 | awk '{print $$2}')
	@kill $$(ps aux | grep $(TARGET).pdf \
		| head -1 | awk '{print $$2}')

clean:
	@if [[ ${MAIN} == main.tex ]]; then\
		$(LATEXMK) $(TEXOPTS) -c;\
	fi

dist-clean: clean-figures
	@$(RM) -r $(OUTDIR) auto \
		*.aux *.log *.out *.pdf *.synctex.gz *.toc

clean-figures:
	@$(RM) -r figures

.PHONY: all clean figures pandoc
