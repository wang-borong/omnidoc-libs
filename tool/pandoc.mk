PANDOC := pandoc

XDG_DATA_DIR ?= $(HOME)/.local/share
OMNIDOC_LIB  ?= $(XDG_DATA_DIR)/omnidoc

PANDOC_OPTS := -f markdown+east_asian_line_breaks+footnotes \
			   --lua-filter=include-code-files.lua \
			   --lua-filter=include-files.lua \
			   --lua-filter=diagram-generator.lua \
			   --metadata=pythonPath:"python3" \
			   --lua-filter=ltblr.lua \
			   --lua-filter=latex-patch.lua \
			   --lua-filter=fonts-and-alignment.lua \
			   -F pandoc-crossref \
			   -M "crossrefYaml=$(OMNIDOC_LIB)/pandoc/crossref.yaml" \
			   --citeproc \
			   --pdf-engine=xelatex \
			   --listings \
			   --data-dir=$(OMNIDOC_LIB)/pandoc/data \
			   --standalone \
			   --embed-resources \
			   --resource-path=.:$(OMNIDOC_LIB)/pandoc/csl:image:images:figure:figures:biblio

# Sorry, we only support the lastest release pandoc
PANDOC_OPTS += --template=pantext.latex

ifneq ($(METADATA_FILE),)
	PANDOC_OPTS += --metadata-file=$(METADATA_FILE).yaml
endif
ifneq ($(V),)
	PANDOC_OPTS += --verbose
endif

TARGET ?= $(shell basename $$PWD)

# Add a '_' to a markdown file name to remove it temporarily.
#SRCS := $(shell find md -regextype sed -regex '.*[^_]c[0-9a-b]\{2\}s[0-9a-b]\{2\}-.*\.md' | sort)
SRCS := main.md

all: $(TARGET).pdf

$(TARGET).pdf: $(SRCS)
	@$(PANDOC) $(PANDOC_OPTS) $^ -o $(BUILDIR)/$@

tex: $(SRCS)
	@$(PANDOC) $(PANDOC_OPTS) \
		$^ -o $(BUILDIR)/$(TARGET).tex

countword: $(SRCS)
	@$(PANDOC) $(PANDOC_OPTS) $^ --lua-filter=wordcount.lua

format: $(SRCS)
	@$(CONTFORM) --markdown $^

.PHONY: all $(TARGET).pdf tex
