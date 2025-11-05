--- abstract.lua – Convert abstract Div blocks to LaTeX abstract environments
---
--- This filter converts Div blocks with the 'abstract' class to LaTeX
--- \begin{abstract} environments. It supports both Chinese and English
--- abstracts, and optional keywords.
---
--- Features:
---   - Converts abstract Div to LaTeX abstract environment
---   - Supports Chinese (c) and English (e) abstracts
---   - Supports optional keywords attribute
---
--- Usage:
---   :::{.abstract .e keywords="keyword1, keyword2"}
---   This is an English abstract.
---   :::
---
---   :::{.abstract .c keywords="关键词1, 关键词2"}
---   这是中文摘要。
---   :::
---
--- Attributes:
---   - keywords: Optional comma-separated list of keywords (added to abstract)

-- ============================================================================
-- Div Processing
-- ============================================================================

--- Convert abstract Div blocks to LaTeX abstract environments
---
--- This function processes Div blocks with the 'abstract' class and converts
--- them to LaTeX \begin{abstract} environments. It handles:
--- - Language specification (Chinese 'c' or English 'e')
--- - Optional keywords
---
--- @param el table The Div element
--- @return table|nil The processed Div with LaTeX abstract environment, or nil if unchanged
function Div(el)
  -- Check if this is an abstract Div
  if el.attr.classes[1] == "abstract" then
    local ret = pandoc.Div({})
    
    -- Determine language: 'e' for English, 'c' for Chinese (default)
    local lang = "c"
    if el.attr.classes[2] == "e" then
      lang = "e"
    end
    
    -- Build abstract environment command
    local abstract_cmd = string.format("\\begin{abstract}{%s}", lang)
    
    -- Add keywords if provided
    if el.attr.attributes["keywords"] ~= nil then
      abstract_cmd = abstract_cmd .. "{" .. el.attr.attributes["keywords"] .. "}"
    end
    
    -- Build the LaTeX abstract environment
    table.insert(ret.content, pandoc.RawBlock("latex", abstract_cmd))
    table.insert(ret.content, el)
    table.insert(ret.content, pandoc.RawBlock("latex", "\\end{abstract}"))
    
    return ret
  end
  
  -- Return nil to leave unchanged
  return nil
end
