--- wrap.lua – Convert Div blocks to LaTeX environments
---
--- This filter converts Div blocks with specific classes into LaTeX environments.
--- It supports various environment types like info boxes, tips, warnings, etc.
---
--- Features:
---   - Converts Div blocks to LaTeX environments based on class names
---   - Supports optional captions for environments
---   - Special handling for list items in introduction and problemset environments
---   - Can hide solution blocks based on metadata
---
--- Supported classes:
---   - info, tip, warn, alert, help: Information boxes
---   - introduction, problemset: Special environments with list support
---   - solu: Solution blocks (can be hidden via metadata)
---
--- Usage:
---   :::{.info caption="Note"}
---   This is an info box.
---   :::
---
---   :::{.solu}
---   This is a solution (can be hidden).
---   :::
---
--- Metadata options:
---   - ext-wrap-solu: Set to true to show solution blocks (default: false, hides them)

-- ============================================================================
-- Configuration
-- ============================================================================

--- List of supported wrap classes
local wrap_classes = {
  'info',
  'tip',
  'warn',
  'alert',
  'help',
  'introduction',
  'problemset',
  'solu'
}

--- Whether to show solution blocks
local show_solutions = false

-- ============================================================================
-- Helper Functions
-- ============================================================================

--- Check if a value is in a table
--- @param t table The table to search
--- @param val any The value to find
--- @return boolean True if the value is in the table
local function in_table(t, val)
  for _, v in pairs(t) do
    if v == val then
      return true
    end
  end
  return false
end

-- ============================================================================
-- Meta Processing
-- ============================================================================

--- Extract configuration from document metadata
--- @param meta table The document metadata
--- @return table|nil The metadata (or nil if unchanged)
function Meta(meta)
  if meta['ext-wrap-solu'] then
    show_solutions = true
  end
  return nil
end

-- ============================================================================
-- Div Processing
-- ============================================================================

--- Wrap a Div block in a LaTeX environment
---
--- This function converts a Div block into a LaTeX environment with the
--- same name as the first class. It handles special cases:
--- - introduction and problemset: Convert BulletList items to \item commands
--- - Other environments: Preserve content as-is
---
--- @param el table The Div element
--- @param option string Optional LaTeX environment option (e.g., for caption)
--- @return table The wrapped Div element
local function wrap(el, option)
  local env_name = el.attr.classes[1]
  local ret = pandoc.Div({})

  -- Begin environment
  table.insert(ret.content, pandoc.RawBlock("latex", string.format(
    "\\begin{%s}%s",
    env_name,
    option
  )))

  -- Special handling for introduction and problemset environments
  -- These need to convert BulletList items to \item commands
  if env_name == 'introduction' or env_name == 'problemset' then
    for _, block in pairs(el.content) do
      if block.t == 'BulletList' then
        -- Convert each list item to a \item command
        for _, item in pairs(block.content) do
          for i, inline in pairs(item) do
            if i == 1 then
              -- First element: add \item command
              table.insert(ret.content, pandoc.RawBlock("latex", "\\item "))
            end
            table.insert(ret.content, inline)
          end
        end
      else
        -- Non-list content: add as-is
        table.insert(ret.content, block)
      end
    end
  else
    -- Other environments: add all content as-is
    for _, block in pairs(el.content) do
      table.insert(ret.content, block)
    end
  end

  -- End environment
  table.insert(ret.content, pandoc.RawBlock("latex", string.format(
    "\\end{%s}",
    env_name
  )))

  return ret
end

--- Process Div blocks and convert them to LaTeX environments
---
--- This function checks if a Div block has a supported wrap class and
--- converts it to the corresponding LaTeX environment. It also handles
--- hiding solution blocks based on metadata.
---
--- @param el table The Div element
--- @return table|nil The processed Div, or an empty Div if solution is hidden
function Div(el)
  -- Check if this is a wrap class
  if not in_table(wrap_classes, el.attr.classes[1]) then
    return nil
  end

  -- Handle solution blocks: hide them if show_solutions is false
  if el.attr.classes[1] == "solu" and not show_solutions then
    return pandoc.Div({})
  end

  -- Get optional caption from attributes
  local option = ""
  if el.attr.attributes['caption'] ~= nil then
    -- Escape underscores in caption (LaTeX special character)
    local caption = el.attr.attributes['caption']:gsub("_", "\\_{}")
    option = "[" .. caption .. "]"
  end

  return wrap(el, option)
end

-- ============================================================================
-- Filter Registration
-- ============================================================================

-- Meta must be processed first to get configuration
-- Then Div blocks are processed
return {
  { Meta = Meta },
  { Div = Div },
}
