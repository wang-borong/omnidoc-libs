--- ltblr.lua – Convert Div blocks to LaTeX tabularray longtblr tables
---
--- This filter converts Div blocks with the 'ltblr' class to LaTeX tabularray
--- longtblr environments. The tabularray package provides a modern, flexible
--- table system for LaTeX with better control over table formatting.
---
--- Features:
---   - Converts Div blocks to LaTeX longtblr environments
---   - Supports custom table options and arguments
---   - Automatic horizontal line insertion
---   - Customizable top/bottom and mid rules
---   - Automatic label insertion for cross-references
---   - Escapes underscores in table content
---
--- Usage:
---   :::{.ltblr #tbl:test-table opts="caption={测试长表格}"
---       args="colspec={|[1.5pt]c|>{\centering\arraybackslash}X|[1.5pt]}, width=0.9\textwidth"
---       tbrule=1.5pt}
---   缩略语 &  英文原文 & 中文含义  
---   CPU & Center Processing Unit & 中央处理器  
---   BSP & Board Support Package & 单板支持软件包
---   
---   PCIE & peripheral component interconnect express & 是一种高速串行计算机扩展总线标准  
---   API & Application Program Interface & 应用程序编程接口  
---   :::
---
--- Attributes:
---   - opts: Optional longtblr options (e.g., caption, positioning)
---   - args: Mandatory longtblr arguments (colspec, width, etc.) - REQUIRED
---   - tbrule: Thickness of top and bottom rules (e.g., "1.5pt")
---   - midrule: Thickness of mid rules (e.g., "1pt")
---   - hashline: Set to "0" to disable automatic horizontal line insertion
---
--- Note:
---   - Blank lines or double spaces at end of line create row breaks
---   - No need to add '\\' at end of lines (handled automatically)
---   - Underscores in content are automatically escaped

-- ============================================================================
-- Div Processing
-- ============================================================================

--- Process table options and arguments
---
--- @param d table The Div element
--- @return string, string|nil Options string and arguments string (args may be nil)
local function process_table_options(d)
  local opts = ''
  local args = nil

  -- Process options (optional)
  if d.attr.attributes['opts'] then
    opts = d.attr.attributes['opts']

    -- Add label if identifier exists and label not already in opts
    if not opts:find('label') and d.attr.identifier then
      opts = string.format('%s, label={%s}', opts, d.attr.identifier)
    end
  elseif d.attr.identifier then
    -- If no opts but identifier exists, add label-only opts
    opts = string.format('label={%s}', d.attr.identifier)
  end

  -- Get mandatory arguments (required)
  if d.attr.attributes['args'] then
    args = d.attr.attributes['args']
  end

  return opts, args
end

--- Process table rules (top/bottom and mid rules)
---
--- @param d table The Div element
--- @return string, string Top/bottom rule string and mid rule string
local function process_table_rules(d)
  local tbrule = ''  -- Top and bottom rule
  local midrule = ''  -- Mid rule (between rows)

  if d.attr.attributes['tbrule'] then
    tbrule = string.format('[%s]', d.attr.attributes['tbrule'])
  end

  if d.attr.attributes['midrule'] then
    midrule = string.format('[%s]', d.attr.attributes['midrule'])
  end

  return tbrule, midrule
end

--- Create inline handler for processing table content
---
--- @param hline_brk string Horizontal line break string
--- @return table Inline handler table
local function create_inline_handler(hline_brk)
  return {
    -- Escape underscores in text (LaTeX special character)
    Str = function(inline)
      return inline.text:gsub('[\\]?_', '\\_')
    end,

    -- Handle line breaks (convert to table row breaks)
    LineBreak = function(_)
      -- Return array with row break and horizontal line
      return { pandoc.RawInline('latex', ' \\\\'), pandoc.RawInline('latex', hline_brk) }
    end,

    -- Handle raw LaTeX inline (filter out \hline if present to avoid duplicates)
    RawInline = function(inline)
      if inline.format == 'latex' and inline.text:match("\\hline.*") then
        -- Skip \hline commands (we add them automatically)
        return nil
      end
      return inline
    end
  }
end

--- Build table content from Div paragraphs
---
--- @param d table The Div element
--- @param tbrule string Top/bottom rule string
--- @param hline_brk string Horizontal line break string
--- @param inline_handler table Inline handler for processing content
--- @return string LaTeX table content string
local function build_table_content(d, tbrule, hline_brk, inline_handler)
  -- Start with top rule
  local table_content = { string.format('\\hline%s', tbrule), '\n' }

  -- Process all paragraphs in the ltblr Div
  local num_paragraphs = #d.content
  for k, para in ipairs(d.content) do
    -- Process paragraph content if it exists
    if para.content then
      -- Walk through inline elements and apply transformations
      local processed_content = para.content:walk(inline_handler)

      -- Add processed content to table
      for _, inline in ipairs(processed_content) do
        table.insert(table_content, inline)
      end

      -- Add row break
      table.insert(table_content, ' \\\\')

      -- Add horizontal line between rows (except after last row)
      if k < num_paragraphs then
        table.insert(table_content, hline_brk)
      else
        -- Add bottom rule after last row
        table.insert(table_content, string.format('\n\\hline%s', tbrule))
      end
    end
  end

  -- Convert table content to string
  return pandoc.utils.stringify(table_content)
end

--- Convert ltblr Div blocks to LaTeX longtblr environments
---
--- This function processes Div blocks with the 'ltblr' class and converts
--- them to LaTeX longtblr environments. It handles:
--- - Table options and arguments
--- - Automatic label insertion from identifier
--- - Customizable table rules
--- - Automatic horizontal line insertion
--- - Content escaping (underscores)
---
--- @param d table The Div element
--- @return table|nil The processed Div with LaTeX longtblr code, or nil if unchanged
local function Div(d)
  -- Check if this is an ltblr Div
  if not d.attr.classes[1] or not string.match(d.attr.classes[1], '^ltblr') then
    return nil
  end

  -- Process table options and arguments
  local opts, args = process_table_options(d)
  if not args then
    -- If args is missing, return the Div unchanged (error condition)
    io.stderr:write("Warning: ltblr Div requires 'args' attribute. Skipping conversion.\n")
    return nil
  end

  -- Process table rules
  local tbrule, midrule = process_table_rules(d)

  -- Build LaTeX environment commands
  local ltblr_begin = string.format('\\begin{ltblr}[%s]{%s}', opts, args)
  local ltblr_end = '\\end{ltblr}'

  -- Determine if automatic horizontal lines should be inserted
  local hashline = true
  if d.attr.attributes['hashline'] and d.attr.attributes['hashline'] == '0' then
    hashline = false
  end

  -- Build horizontal line break string
  local hline_brk = hashline and string.format('\n\\hline%s\n', midrule) or '\n'

  -- Create inline handler
  local inline_handler = create_inline_handler(hline_brk)

  -- Build table content
  local ltblr_content = build_table_content(d, tbrule, hline_brk, inline_handler)

  -- Build result as LaTeX raw blocks
  return {
    pandoc.RawBlock('latex', ltblr_begin),
    pandoc.RawBlock('latex', ltblr_content),
    pandoc.RawBlock('latex', ltblr_end),
  }
end

-- ============================================================================
-- Filter Registration
-- ============================================================================

return {
  { Div = Div },
}
