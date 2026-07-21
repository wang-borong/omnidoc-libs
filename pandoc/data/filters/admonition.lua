--- admonition.lua - Render semantic admonition Divs across output formats.
---
--- Markdown input:
---   ::: {.admonition .hint title="提示"}
---   Think about where the output energy comes from.
---   :::
---
--- LaTeX output is wrapped in an OmniHint tcolorbox. HTML and EPUB retain a
--- semantic Div with a data-title attribute so that CSS can style it.

local is_latex = FORMAT:match('latex') or FORMAT:match('beamer')
local utils = pandoc.utils

local function has_class(el, class_name)
  for _, class in ipairs(el.classes) do
    if class == class_name then
      return true
    end
  end
  return false
end

local function escape_latex(value)
  local replacements = {
    ['\\'] = '\\textbackslash{}',
    ['{'] = '\\{',
    ['}'] = '\\}',
    ['#'] = '\\#',
    ['$'] = '\\$',
    ['%'] = '\\%',
    ['&'] = '\\&',
    ['_'] = '\\_',
    ['^'] = '\\textasciicircum{}',
    ['~'] = '\\textasciitilde{}',
  }
  return (value:gsub('[\\{}#$%%&_^~]', replacements))
end

function Meta(meta)
  if not is_latex then
    return nil
  end

  local package = pandoc.MetaBlocks({
    pandoc.RawBlock('latex', '\\usepackage{omni-admonitions}')
  })
  local includes = meta['header-includes']
  if includes == nil then
    meta['header-includes'] = pandoc.MetaList({ package })
  elseif utils.type(includes) == 'List' then
    table.insert(includes, package)
  else
    meta['header-includes'] = pandoc.MetaList({ includes, package })
  end
  return meta
end

function Div(el)
  if not has_class(el, 'admonition') or not has_class(el, 'hint') then
    return nil
  end

  local title = el.attributes.title or '提示'
  el.attributes.title = nil

  if is_latex then
    local blocks = {
      pandoc.RawBlock('latex', '\\begin{OmniHint}{' .. escape_latex(title) .. '}')
    }
    for _, block in ipairs(el.content) do
      table.insert(blocks, block)
    end
    table.insert(blocks, pandoc.RawBlock('latex', '\\end{OmniHint}'))
    return blocks
  end

  el.attributes['data-title'] = title
  return el
end

return {
  { Meta = Meta },
  { Div = Div },
}
