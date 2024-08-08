XDG_DATA_DIR := $(HOME)/.local/share
OMNIDOC_LIB  := $(XDG_DATA_DIR)/omnidoc

LATEXMK := latexmk
FIGENERATOR := python3 $(XDG_DATA_DIR)/tool/figure-generator.py
BITFIELD := python $(XDG_DATA_DIR)/tool/bit-field.py
CONTFORM := perl $(XDG_DATA_DIR)/tool/content-formatter.pl
PANDOCMK := $(XDG_DATA_DIR)/tool/pandoc.mk
# set metadata file for pandoc (located in pandoc/data/metadata)
# or eleg-book, eleg-paper, eleg-note
# METADATA_FILE  ?= eleg-book

OUTDIR ?= build
BUILDIR := $(PWD)/$(OUTDIR)

ifeq ($(V),)
	TEXOPTS += -quiet
	NOINFO := > /dev/null 2>&1
endif

MAIN ?= $(shell ls main.*)
TEXES := $(shell find . -name "*.tex" | sort)

FIGSRC := $(wildcard drawio/*.drawio)
FIGSRC += $(wildcard dac/*)
SVGSRC := $(wildcard figure/*.svg)

TARGET ?= 

export TARGET CONTFORM BUILDIR METADATA_FILE XDG_DATA_DIR OMNIDOC_LIB

all: $(BUILDIR)
	@if [[ ${MAIN} == "main.md" ]]; then make pandoc; else make latex; fi

latex: $(BUILDIR)/$(TARGET).tex
	@if [[ ! -d figures ]]; then make figures; fi
	@$(LATEXMK) $(TEXOPTS) $< || $(LATEXMK) -c $<

pandoc: $(BUILDIR)
	@make -f $(PANDOCMK)

$(BUILDIR)/$(TARGET).tex: $(MAIN) $(BUILDIR)
	@if [[ ! -f $@ ]]; then ln -sf ../$< $@; fi

$(BUILDIR):
	@mkdir -p $@

pandoc-tex: $(BUILDIR)
	@make -f $(PANDOCMK) tex

format: $(TEXES)
	@$(CONTFORM) $^
	@make -f $(PANDOCMK) format

figures: $(FIGSRC) $(SVGSRC)
	@mkdir -p figures
	@$(FIGENERATOR) $(FIGSRC)
	@for json in dac/*.json; do $(BITFIELD) --fontsize=9 $$json figures/$$(basename $${json%%.*}).svg; done
	@$(FIGENERATOR) -c $(SVGSRC) figures/*.svg

latex-view: latex
	@$(LATEXMK) -f -pvc -view=pdf $(BUILDIR)/$(TARGET) $(NOINFO) &

pandoc-view: pandoc-tex latex
	@$(LATEXMK) -f -pvc -view=pdf $(BUILDIR)/$(TARGET) $(NOINFO) &

kill-view:
	@kill $$(ps aux | grep "latexmk -f -pvc" \
		| head -1 | awk '{print $$2}')
	@kill $$(ps aux | grep $(TARGET).pdf \
		| head -1 | awk '{print $$2}')

clean: $(BUILDIR)/$(TARGET).pdf
	@$(RM) $<
	@if [[ ${MAIN} == main.tex ]]; then $(LATEXMK) -c main.tex; fi

dist-clean:
	@$(RM) -r $(OUTDIR) auto \
		*.aux *.log *.out *.pdf *.synctex.gz *.toc

clean-figures:
	@$(RM) -r figures

.PHONY: all clean figures pandoc
