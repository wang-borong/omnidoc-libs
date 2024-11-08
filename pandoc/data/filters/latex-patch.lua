-- local logging = require 'logging'
local function latex(str)
  return pandoc.RawInline('latex', str)
end

local function starts_with(start, str)
  return str:sub(1, #start) == start
end

local function fix_rawinline (rl)
  -- logging.temp('rawinlines', rl)
  -- add a ~ to the begin of \ref
  if starts_with('\\ref', rl.text)
  then
    local nel = string.gsub(rl.text, '[ ~]*(.*) *', '~%1')
    return latex(nel)
  end

  return rl
end

-- local function contains_key(list, x)
-- 	for k, _ in pairs(list) do
-- 		if k == x then return true end
-- 	end
-- 	return false
-- end

local function contains_value(list, x)
	for _, v in pairs(list) do
		if v == x then return true end
	end
	return false
end

local function execute_command(cmd)
  local handle = io.popen(cmd)
  if handle then
    local output = handle:read("*a")
    handle:close()
    return output
  end
end

local function check_file_ext(fn, legal_ext)
  local fe = fn:match("^.+%.(.+)$")
  return contains_value(legal_ext, fe)
end

local function proc_image(image)
  -- local nimg_attr = {}
  -- if contains_key(image.attributes, 'width') then
  --   nimg_attr = image.attributes
  --   nimg_attr.height = nimg_attr.width
  -- else
  --   nimg_attr.width = '100%'
  --   nimg_attr.height = '100%'
  -- end
  -- image.attributes = nimg_attr

  -- if don't add image suffix to its name
  -- we find its real name

  if not image.src then return image end
  if image.src:match('figures?/', 1) or image.src:match('images?/') then
    return
  end

  local legal_ext = {'pdf', 'png', 'jpg', 'ps', 'fig', 'eps'}

  local cmd = string.format(
    'find . -type d %s %s -o -name "%s*" -print | sed "/.svg/d"',
    '\\( -name appendix -o -name dac -o -name drawio -o -name pandoc',
    '-o -name reference -o -name texmf -o -name tool -o -name .git \\) -prune',
    image.src:match("[^/]*$"))
  -- logging.output('cmd:', cmd)
  local output = execute_command(cmd)
  if output == '' then return image end
  -- logging.output('out:', output)
  -- Extracts basename of the found path
  local img_name = output:gsub("%./.-/(.*)", "%1"):gsub("\n$", "")
  -- logging.output('img_name:', img_name)

  if check_file_ext(img_name, legal_ext) then
    image.src = img_name
  end

  return image
end

-- local function proc_citation(ct)
--   logging.temp('citation', ct)
-- end

local function is_space_before_ref(spc, ref)
  return (spc and spc.t == 'Space')
    and ((ref and ref.t == 'RawInline' and starts_with('~', ref.text))
    or (ref and ref.t == 'Cite' and starts_with('fig:', ref.citations[1].id))
    or (ref and ref.t == 'Cite' and starts_with('tbl:', ref.citations[1].id))
    or (ref and ref.t == 'Cite' and starts_with('lst:', ref.citations[1].id))
    or (ref and ref.t == 'Cite' and starts_with('sec:', ref.citations[1].id))
    or (ref and ref.t == 'Cite' and starts_with('eq:',  ref.citations[1].id))
    -- or (ref and ref.t == 'Str' and ref.text:match("[,%.;:…%)，。、：；’”》]", 1))
  )
end

local function no_space_after_ref(ref, next)
  return ((ref and ref.t == 'RawInline' and starts_with('~', ref.text))
    or (ref and ref.t == 'Cite' and starts_with('fig:', ref.citations[1].id))
    or (ref and ref.t == 'Cite' and starts_with('tbl:', ref.citations[1].id))
    or (ref and ref.t == 'Cite' and starts_with('lst:', ref.citations[1].id))
    or (ref and ref.t == 'Cite' and starts_with('sec:', ref.citations[1].id))
    or (ref and ref.t == 'Cite' and starts_with('eq:',  ref.citations[1].id)))
    and (next and next.t == 'Str' and not next.text:match("[,%.;:…%)，。、：；’”》]", 1))
end

local function proc_inlines(inlines)
  -- logging.temp('inlines', inlines)
  for i = #inlines-1, 1, -1 do
    if is_space_before_ref(inlines[i], inlines[i+1]) then
      -- logging.temp('inlines', inlines)
      inlines:remove(i)
      -- logging.temp('new-inlines', inlines)
    end
    if no_space_after_ref(inlines[i], inlines[i+1]) then
      inlines:insert(i+1, pandoc.Space())
    end
  end
  -- logging.temp('new-inlines', inlines)
  return inlines
end

return {
  {RawInline = fix_rawinline},
  {Image = proc_image},
  -- {Citation = proc_citation},
  {Inlines = proc_inlines},
}
