-- A filter to converting ltblr div to latex table (tabularray longtblr)
-- {
-- * opts="" used to specify longtblr options
-- * args="" used to specify longtblr mandatory arguments
-- * tbrule is the top and bottom line rule
-- * midrule is the rest line rule
-- * \hlines are added by the filter automatically.
--   But if you don't want the automation, you can set 'hashline=0'.
-- * No '\\' at the end of line is needed, but with two space as hard breakline.
--   Or you can use a blank line to separate two table lines.
--
-- e.g.:
-- :::{.ltblr #tbl:test-table opts="caption={测试长表格}"
--     args="colspec={|[1.5pt]c|>{\centering\arraybackslash}X|[1.5pt]}, width=0.9\textwidth"
--     tbrule=1.5pt}
--   缩略语 &  英文原文 & 中文含义  
--   CPU & Center Proccessing Unit & 中央处理器  
--   BSP & Board Support Package & 单板支持软件包
--            <!-- blank line to separate table lines ---!>
--   PCIE & peripheral component interconnect express & 是一种高速串行计算机扩展总线标准  
--   API & Application Program Interface & 应用程序编程接口  
--   &  &
-- :::
--
-- 如 [@tbl:ltblr_test] 所示
--
-- }

-- local logging = require("logging")

local function Div(d)
	if not string.match(d.attr.classes[1], '^ltblr') then
		return d
	end

  -- opts="..." args="..."
  local opts = ''
  local args = ''
  if d.attr.attributes['opts'] then
    opts = d.attributes['opts']
    if not opts:find('label') then
      if d.attr.identifier then
        opts = string.format('%s, label={%s}', opts, d.attr.identifier)
      -- else
      --   return d
      end
    end
  end

  local tbrule = ''
  local midrule = ''
  if d.attributes['tbrule'] then
    tbrule = string.format('[%s]', d.attributes['tbrule'])
  end
  if d.attributes['midrule'] then
    midrule = string.format('[%s]', d.attributes['midrule'])
  end

  if d.attr.attributes['args'] then
    args = d.attr.attributes['args']
  else
    return d
  end

  local ltblr_begin = string.format('\\begin{ltblr}[%s]{%s}', opts, args)
  local ltblr_end = '\\end{ltblr}'

  local hashline = true
  if d.attributes['hashline'] and d.attributes['hashline'] == '0' then
    hashline = false
  end

  local hline_brk = ''
  if hashline then
    hline_brk = string.format('\n\\hline%s\n', midrule)
  else
    hline_brk = '\n'
  end

  local tblr_inline_handler = {
    Str = function (inline)
      return inline.text:gsub('[\\]?_', '\\_')
    end,
    LineBreak = function (_)
      local _append = {' \\\\'}
      table.insert(_append, hline_brk)
      return _append
    end,
    RawInline = function (inline)
      if not inline.text:match("\\hline.*") then
        return inline.text
      end
    end
  }

  -- we should stringify the nc, so inserting string is ok
  local nc = { string.format('\\hline%s', tbrule), '\n' }
  -- hangle all paras in ltblr div
  local dcn = #d.content
  for k, v in pairs(d.content) do
    if v.content then
      table.insert(nc, v.content:walk(tblr_inline_handler))
      table.insert(nc, ' \\\\')
      if k < dcn then
        table.insert(nc, hline_brk)
      else
        table.insert(nc, string.format('\n\\hline%s', tbrule))
      end
    end
  end

  -- stringify the table content
  local ltblr_content = pandoc.utils.stringify(nc)

	local nd = {
    pandoc.RawBlock('latex', ltblr_begin),
    pandoc.RawBlock('latex', ltblr_content),
    pandoc.RawBlock('latex', ltblr_end),
  }

  return nd
end

return {
  { Div = Div },
}
