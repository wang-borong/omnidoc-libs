--- fenced_divs_columns.lua – Convert column Div blocks to LaTeX columns
---
--- This filter converts Div blocks with the 'columns' class and nested
--- 'column' Div blocks into LaTeX column environments. This allows creating
--- multi-column layouts in LaTeX documents.
---
--- Features:
---   - Converts columns Div to LaTeX \begin{columns} environment
---   - Converts nested column Divs to LaTeX \begin{column} environments
---   - Supports custom column widths via width attribute
---   - Automatically calculates column spacing
---
--- Usage:
---   :::{.columns}
---   :::{.column width="50%"}
---   Left column content.
---   :::
---   :::{.column width="50%"}
---   Right column content.
---   :::
---   :::
---
--- Attributes:
---   - width: Column width as percentage (e.g., "50%"). Default is 48% (accounts for spacing).

-- ============================================================================
-- Helper Functions
-- ============================================================================

--- Extract width percentage and convert to LaTeX textwidth fraction
---
--- This function parses a width attribute (e.g., "50%") and converts it
--- to a fraction of textwidth suitable for LaTeX. The function accounts
--- for spacing between columns by using a denominator of 104 instead of 100.
---
--- @param width string|nil The width attribute (e.g., "50%")
--- @return string The width as a LaTeX textwidth fraction (e.g., "0.48")
local function get_width(width)
  if width == nil then
    return "0.48"  -- Default width
  end
  
  -- Extract percentage number from string (e.g., "50%" -> "50")
  local width_num = string.match(width, "(%d+)%%$")
  
  if width_num == nil then
    return "0.48"  -- Default if parsing fails
  end
  
  -- Convert percentage to fraction
  -- Using 104 as denominator accounts for spacing between columns
  local fraction = tonumber(width_num) / 104
  
  -- Ensure width is reasonable (between 0 and 1)
  if fraction < 0 then
    fraction = 0.48
  elseif fraction > 1 then
    fraction = 0.98  -- Leave some margin
  end
  
  return string.format("%.2f", fraction)
end

-- ============================================================================
-- Column Processing
-- ============================================================================

--- Process column Div blocks and convert them to LaTeX column environments
---
--- This function processes a list of blocks and converts column Div blocks
--- into LaTeX \begin{column} and \end{column} environments. It handles:
--- - Opening column environments when a column Div is encountered
--- - Closing and opening new columns when multiple columns are adjacent
--- - Closing the last column environment
--- - Preserving non-column content as-is
---
--- @param blocks table List of block elements (may contain column Divs)
--- @return table A Div containing the processed blocks with LaTeX column commands
local function div_columns(blocks)
  local result = pandoc.Div({})
  
  for i, block in pairs(blocks) do
    -- Check if this is a column Div
    if block.t == "Div" and block.attr.classes[1] == "column" then
      -- Check if previous block was also a column (to avoid duplicate begin)
      local prev_is_column = (i > 1 and 
                              blocks[i - 1].t == "Div" and 
                              blocks[i - 1].attr.classes[1] == "column")
      
      if not prev_is_column then
        -- Start new column environment
        local width = get_width(block.attr.attributes.width)
        table.insert(result.content, pandoc.RawBlock("latex",
          string.format("\\begin{column}{%s\\textwidth}", width)))
      end
      
      -- Add column content
      for _, content in pairs(block.content) do
        table.insert(result.content, content)
      end
      
      -- Check if next block is also a column
      local next_is_column = (i + 1 <= #blocks and
                              blocks[i + 1].t == "Div" and
                              blocks[i + 1].attr.classes[1] == "column")
      
      if next_is_column then
        -- Close current column and open next
        local next_width = get_width(blocks[i + 1].attr.attributes.width)
        table.insert(result.content, pandoc.RawBlock("latex",
          string.format("\\end{column}\n\\begin{column}{%s\\textwidth}", next_width)))
      else
        -- Close column environment
        table.insert(result.content, pandoc.RawBlock("latex", "\\end{column}"))
      end
    else
      -- Non-column content: add as-is
      table.insert(result.content, block)
    end
  end
  
  return result
end

-- ============================================================================
-- Document Processing
-- ============================================================================

--- Process the document and convert columns Divs to LaTeX column environments
---
--- This function processes the document and converts any Div blocks with
--- the 'columns' class into LaTeX \begin{columns} environments, with nested
--- column Divs converted to LaTeX column environments.
---
--- @param doc table The Pandoc document
--- @return table The processed document with LaTeX column environments
function Pandoc(doc)
  local new_blocks = {}
  
  for _, block in pairs(doc.blocks) do
    -- Check if this is a columns Div
    if block.t == "Div" and block.attr.classes[1] == "columns" then
      -- Start columns environment
      table.insert(new_blocks, pandoc.RawBlock("latex", "\\begin{columns}"))
      
      -- Process nested column Divs
      table.insert(new_blocks, div_columns(block.content))
      
      -- End columns environment
      table.insert(new_blocks, pandoc.RawBlock("latex", "\\end{columns}"))
    else
      -- Non-columns content: add as-is
      table.insert(new_blocks, block)
    end
  end
  
  return pandoc.Pandoc(new_blocks, doc.meta)
end
