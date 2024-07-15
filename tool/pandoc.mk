PANDOC := pandoc

PANDOC_OPTS := -f markdown+east_asian_line_breaks+footnotes \
			   --lua-filter=include-code-files.lua \
			   --lua-filter=include-files.lua \
			   --lua-filter=diagram-generator.lua \
			   --metadata=pythonPath:"python3" \
			   --lua-filter=ltblr.lua \
			   --lua-filter=latex-patch.lua \
			   --lua-filter=fonts-and-alignment.lua \
			   -F pandoc-crossref \
			   -M "crossrefYaml=pandoc/crossref.yaml" \
			   --citeproc \
			   --pdf-engine=xelatex \
			   --listings \
			   --data-dir=pandoc/data \
			   --standalone \
			   --embed-resources \
			   --resource-path=.:pandoc/csl:image:images:figure:figures:biblio

PANDOC_VER := $(shell $(PANDOC) -v | head -1 | awk '{print $$2}' \
			  | sed -E -e 's/\.//g' -e 's/([0-9])(.*)/\1\.\2/' \
			  | awk '{printf "%.03f", $$1}' | sed 's/\.//g')
PANDOC_GTEAT_THAN_3_1_7 := $(shell echo "$(PANDOC_VER) 3107" \
						   | awk '{if($$1>=$$2) {print 1} else {print 0}}')

ifeq ($(PANDOC_GTEAT_THAN_3_1_7),1)
	PANDOC_OPTS += --template=pantext.latex
else
	PANDOC_OPTS += --template=pantext-3107-.latex
endif

ifneq ($(METADATA_FILE),)
	PANDOC_OPTS += --metadata-file=$(METADATA_FILE).yaml
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

.PHONY: all $(TARGET).pdf
