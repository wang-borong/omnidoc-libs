--- tabu.lua – Convert tables to LaTeX tabu/longtabu environments
---
--- This filter converts Pandoc tables to LaTeX tabu or longtabu environments.
--- The tabu package provides flexible column widths and better table control
--- than standard LaTeX tables.
---
--- Features:
---   - Converts tables to LaTeX tabu environments
---   - Supports long tables (longtabu) for multi-page tables
---   - Automatic column width calculation based on table widths
---   - Supports table captions and labels (works with pandoc-crossref)
---   - Handles headers and data rows
---
--- Usage:
---   Markdown tables are automatically converted. To use longtabu, add
---   {.longtabu} to the table caption:
---
---   Table: Caption {.longtabu}
---   | Header 1 | Header 2 |
---   |----------|----------|
---   | Data 1   | Data 2   |
---
--- Note: This filter only works for LaTeX/PDF output. For other formats,
---       it returns an empty filter (no processing).

-- Only process LaTeX/PDF output
if FORMAT ~= "latex" and FORMAT ~= "tex" and FORMAT ~= "pdf" then
  return {}
end

-- ============================================================================
-- Helper Functions
-- ============================================================================

--- Check if a table should use longtabu
---
--- This function checks the table caption to determine if it should use
--- longtabu (for multi-page tables) or regular tabu. The check looks for
--- {.longtabu} or {.longtable} in the caption.
---
--- Note: pandoc-crossref adds \label, so {.longtabu} is typically the
---       second element in the caption.
---
--- @param caption table List of inline elements in the caption
--- @return number 0 = regular tabu, 1 = longtabu, 2 = skip (use pandoc longtable)
local function check_longtabu(caption)
  if #caption >= 2 then
    -- Check for {.longtabu} marker (second element after pandoc-crossref label)
    if caption[2].text == "{.longtabu}" then
      return 1  -- Use longtabu
    elseif caption[2].text == "{.longtable}" then
      -- Use pandoc's native longtable instead
      print("with {.longtable} ... [SKIP]")
      return 2  -- Skip tabu conversion, use pandoc longtable
    end
  end
  return 0  -- Regular tabu
end

--- Convert alignment enum to LaTeX alignment character
---
--- @param align string Pandoc alignment enum (AlignLeft, AlignRight, AlignCenter)
--- @return string LaTeX alignment character (l, r, c)
local function align_to_latex(align)
  if align == "AlignRight" then
    return "r"
  elseif align == "AlignCenter" then
    return "c"
  else
    return "l"  -- Default to left alignment
  end
end

-- ============================================================================
-- Tabu Table Generation
-- ============================================================================

--- Build column specification string for tabu
---
--- @param tbl table SimpleTable object
--- @return string Column specification string (e.g., "X[10.00,l]X[20.00,c]")
local function build_column_spec(tbl)
  local column_spec = ""

  for i, width in ipairs(tbl.widths) do
    -- Convert width to tabu format (multiply by 10, format to 2 decimals)
    local width_value = string.format("%.2f", width * 10)

    -- Ensure minimum width (0.0 causes LaTeX errors)
    if width == 0.0 then
      width_value = "1"
    end

    -- Get alignment for this column
    local align = align_to_latex(tbl.aligns[i])

    -- Build column specification: X[width,alignment]
    column_spec = column_spec .. string.format("X[%s,%s]", width_value, align)
  end

  return column_spec
end

--- Check if table has headers
---
--- @param tbl table SimpleTable object
--- @return boolean True if table has headers
local function table_has_headers(tbl)
  for _, header_cell in ipairs(tbl.headers) do
    if #header_cell > 0 then
      return true
    end
  end
  return false
end

--- Add table headers to table blocks
---
--- @param tbl table SimpleTable object
--- @param table_blocks table List to add blocks to
local function add_table_headers(tbl, table_blocks)
  local column_sep = pandoc.RawBlock("latex", " & ")
  local row_end = pandoc.RawBlock("latex", " \\\\\n")

  local num_columns = #tbl.headers
  for col = 1, num_columns do
    -- Add header cell content
    for _, inline in ipairs(tbl.headers[col]) do
      table.insert(table_blocks, inline)
    end
    -- Add column separator (except for last column)
    if col < num_columns then
      table.insert(table_blocks, column_sep)
    end
  end
  -- End header row
  table.insert(table_blocks, row_end)
  table.insert(table_blocks, pandoc.RawBlock("latex", " \\midrule\n"))
end

--- Add table data rows to table blocks
---
--- @param tbl table SimpleTable object
--- @param table_blocks table List to add blocks to
local function add_table_rows(tbl, table_blocks)
  local column_sep = pandoc.RawBlock("latex", " & ")
  local row_end = pandoc.RawBlock("latex", " \\\\\n")

  local num_columns = #tbl.aligns
  for row = 1, #tbl.rows do
    for col = 1, num_columns do
      -- Add cell content
      for _, inline in ipairs(tbl.rows[row][col]) do
        table.insert(table_blocks, inline)
      end
      -- Add column separator (except for last column)
      if col < num_columns then
        table.insert(table_blocks, column_sep)
      end
    end
    -- End row
    table.insert(table_blocks, row_end)
  end
end

--- Convert a SimpleTable to LaTeX tabu/longtabu code
---
--- This function converts a Pandoc SimpleTable to LaTeX tabu or longtabu
--- environment. It handles:
--- - Column width specification (X columns with width and alignment)
--- - Table headers
--- - Table rows
--- - Captions
--- - Table rules (toprule, midrule, bottomrule)
---
--- @param tbl table SimpleTable object (from pandoc.utils.to_simple_table)
--- @param longtable boolean Whether to use longtabu (true) or tabu (false)
--- @param caption table List of inline elements for the caption
--- @return table A Para block containing the LaTeX table code
local function generate_tabu(tbl, longtable, caption)
  -- Determine LaTeX macro names
  local macro_begin = longtable and "\\begin{longtabu}" or "\\begin{tabu}"
  local macro_end = longtable and "\\end{longtabu}" or "\\end{tabu}"

  -- Build column specification
  local column_spec = build_column_spec(tbl)

  -- Start building the table
  local table_blocks = {}

  -- Add table begin and column specification
  table.insert(table_blocks, pandoc.RawBlock("latex",
    string.format("%s{%s}\n", macro_begin, column_spec)))

  -- Handle caption (position differs for tabu vs longtabu)
  if #caption > 0 then
    local caption_begin = pandoc.RawBlock("latex", "\\caption{")
    local caption_para = pandoc.Para({})
    caption_para.content = caption
    local caption_end = pandoc.RawBlock("latex", "}\\tabularnewline\n")

    if longtable then
      -- longtabu: caption comes after \begin
      table.insert(table_blocks, caption_begin)
      table.insert(table_blocks, caption_para)
      table.insert(table_blocks, caption_end)
    end
    -- tabu: caption comes before \begin (handled by caller)
  end

  -- Add top rule
  table.insert(table_blocks, pandoc.RawBlock("latex", "\\toprule\n"))

  -- Add headers if present
  if table_has_headers(tbl) then
    add_table_headers(tbl, table_blocks)
  end

  -- Add data rows
  add_table_rows(tbl, table_blocks)

  -- Add bottom rule and end table
  table.insert(table_blocks, pandoc.RawBlock("latex",
    string.format("\\bottomrule\n%s", macro_end)))

  -- Convert blocks to inlines and wrap in Para
  local table_inlines = pandoc.utils.blocks_to_inlines(table_blocks, {})
  local result = pandoc.Para({})
  result.content = table_inlines

  return result
end

-- ============================================================================
-- Table Processing
-- ============================================================================

--- Extract table from Div or Table element
---
--- @param el table Div or Table element
--- @return table|nil The Table element, or nil if not found
local function extract_table(el)
  if el.t == "Div" then
    if el.content[1] and el.content[1].t == "Table" then
      return el.content[1]
    end
  elseif el.t == "Table" then
    return el
  end
  return nil
end

--- Create regular tabu table wrapped in table environment
---
--- @param simple_table table SimpleTable object
--- @param caption table Caption blocks
--- @param identifier string|nil Table identifier
--- @return table Div containing the wrapped table
local function create_regular_tabu(simple_table, caption, identifier)
  local result_div = pandoc.Div({})
  if identifier then
    result_div.attr.identifier = identifier
  end

  local wrap_div = pandoc.Div({})

  if #caption > 0 then
    table.insert(wrap_div.content, pandoc.RawBlock("latex",
      "\\begin{table}[h]\n\\begin{center}"))
  end

  table.insert(result_div.content, generate_tabu(simple_table, false, caption))
  table.insert(wrap_div.content, result_div)

  if #caption > 0 then
    table.insert(wrap_div.content, pandoc.RawBlock("latex",
      "\\end{center}\n\\end{table}"))
  end

  return wrap_div
end

--- Create longtabu table (no wrapping)
---
--- @param simple_table table SimpleTable object
--- @param caption table Caption blocks
--- @param identifier string|nil Table identifier
--- @return table Div containing the longtabu table
local function create_longtabu(simple_table, caption, identifier)
  local result_div = pandoc.Div({})
  if identifier then
    result_div.attr.identifier = identifier
  end

  -- Remove the {.longtabu} marker from caption
  if #caption >= 2 and caption[2].text == "{.longtabu}" then
    caption[2] = pandoc.Str("")
  end

  table.insert(result_div.content, generate_tabu(simple_table, true, caption))
  return result_div
end

--- Handle native longtable (skip tabu conversion)
---
--- @param el table Original element
--- @return table Element with {.longtable} marker removed
local function handle_native_longtable(el)
  -- Remove the {.longtable} marker
  if el.t == "Div" and el.content[1] then
    if el.content[1].caption and #el.content[1].caption >= 2 then
      el.content[1].caption[2] = pandoc.Str("")
    end
  elseif el.caption and #el.caption >= 2 then
    el.caption[2] = pandoc.Str("")
  end
  return el
end

--- Process and convert a table or Div containing a table to LaTeX tabu
---
--- This function processes tables and converts them to LaTeX tabu environments.
--- It handles:
--- - Regular tables (wrapped in table environment)
--- - Long tables (longtabu, no wrapping)
--- - Tables with labels from pandoc-crossref
---
--- @param el table Table or Div element containing a table
--- @return table The processed element with LaTeX tabu code
local function render_tabu(el)
  -- Check if this is a Div with a table label (from pandoc-crossref)
  -- pandoc-crossref uses id prefix "tbl:" for tables
  if el.t == "Div" and not string.match(el.attr.identifier or "", '^tbl:.*') then
    return el  -- Not a labeled table, skip
  end

  -- Extract table from element
  local tbl = extract_table(el)
  if not tbl then
    return el  -- Not a table, skip
  end

  -- Convert to SimpleTable for easier processing
  local simple_table = pandoc.utils.to_simple_table(tbl)
  local caption = simple_table.caption
  local is_longtabu = check_longtabu(caption)
  local identifier = (el.t == "Div") and el.attr.identifier or nil

  -- Handle different table types
  if is_longtabu == 0 then
    -- Regular tabu: wrap in table environment
    return create_regular_tabu(simple_table, caption, identifier)
  elseif is_longtabu == 1 then
    -- longtabu: no wrapping needed
    return create_longtabu(simple_table, caption, identifier)
  elseif is_longtabu == 2 then
    -- Skip tabu conversion, use pandoc's native longtable
    return handle_native_longtable(el)
  end

  return el  -- Fallback: return unchanged
end

-- ============================================================================
-- Document Processing
-- ============================================================================

--- Process the document and convert tables to LaTeX tabu
---
--- This function processes all tables in the document and converts them
--- to LaTeX tabu or longtabu environments.
---
--- @param doc table The Pandoc document
--- @return table The processed document with LaTeX tabu tables
function Pandoc(doc)
  local new_blocks = {}
  
  for _, block in ipairs(doc.blocks) do
    if block.t == "Div" or block.t == "Table" then
      block = render_tabu(block)
    end
    table.insert(new_blocks, block)
  end
  
  return pandoc.Pandoc(new_blocks, doc.meta)
end
