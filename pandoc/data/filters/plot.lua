--- plot.lua – Convert code blocks to images using various plotting engines
---
--- This filter converts code blocks with "plot:engine" classes into images
--- using various plotting and diagram generation tools. It supports multiple
--- engines including GraphViz, TikZ, Gnuplot, Asymptote, and more.
---
--- Features:
---   - Multiple plotting engines: GraphViz (dot, neato, etc.), TikZ, Gnuplot,
---     Asymptote, ditaa, goseq, a2s, abcm2ps
---   - Automatic format selection based on output format
---   - File caching to avoid regenerating images
---   - Support for subfigures (multiple images in one figure)
---   - Customizable file output directories
---
--- Usage:
---   ```{.plot:dot}
---   digraph G {
---     A -> B
---   }
---   ```
---
---   ```{.plot:tikz}
---   \draw (0,0) circle (1cm);
---   ```
---
---   ```{.plot:gnuplot}
---   plot sin(x)
---   ```
---
--- Supported Engines:
---   - GraphViz family: dot, neato, fdp, sfdp, twopi, circo
---   - TikZ: tikz (requires xelatex)
---   - Gnuplot: gnuplot
---   - Asymptote: asy
---   - ditaa: ASCII art diagrams
---   - goseq: Sequence diagrams
---   - a2s: ASCII to SVG
---   - abcm2ps/abc: Music notation
---
--- Note: This filter requires the corresponding plotting tools to be installed
---       and available in the system PATH.

-- ============================================================================
-- Configuration
-- ============================================================================

--- Directory for rendered images
local render_dir = "figures"

--- Directory for source code files
local code_dir = "diagascode"

-- Create directories if they don't exist
if not os.execute("[ -d " .. render_dir .. " ]") then
  os.execute("mkdir -p " .. render_dir)
end
if not os.execute("[ -d " .. code_dir .. " ]") then
  os.execute("mkdir -p " .. code_dir)
end

-- ============================================================================
-- Helper Functions
-- ============================================================================

--- Check if a value is in a table
---
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

--- Get all keys from a table
---
--- @param t table The table
--- @return table Array of keys
local function table_keys(t)
  local keys = {}
  for k, _ in pairs(t) do
    keys[#keys + 1] = k
  end
  return keys
end

--- Check if a file exists
---
--- @param filename string The file path
--- @return boolean True if the file exists
local function file_exists(filename)
  return os.execute("[ -f " .. filename .. " ]")
end

--- Check if a command is available in PATH
---
--- @param command string The command name
--- @return boolean True if the command is available
local function which(command)
  return os.execute("which " .. command .. ' >/dev/null 2>&1')
end

--- Convert SVG to other formats using rsvg-convert
---
--- @param svg string Path to SVG file
--- @param output string Path to output file
--- @param format string Output format (png, pdf, etc.)
--- @return boolean True on success, false on error
local function rsvg_convert(svg, output, format)
  if not which('rsvg-convert') then
    print("\27[31mPlot Warning: librsvg not installed!\27[m")
    return false
  end

  local result = os.execute('rsvg-convert -f ' .. format .. ' -o ' ..
                           output .. ' ' .. svg)

  if not result then
    print("\27[31mPlot Warning: rsvg convert failed! -> " .. svg .. "\27[m")
  end
  return result
end

--- Get appropriate file type for an engine based on output format
---
--- @param engine string The engine name
--- @return string The file type (pdf, png, svg)
local function get_filetype(engine)
  -- Default format is PDF
  local filetype = "pdf"

  -- Some output formats don't support PDF well, use PNG
  if in_table({'docx', 'pptx', 'rtf'}, FORMAT) then
    filetype = "png"
  end

  -- Web formats prefer SVG
  if in_table({'epub', 'epub2', 'epub3', 'html', 'html5'}, FORMAT) then
    filetype = "svg"
  end

  -- Some engines don't support SVG, force PNG
  if in_table({"ditaa"}, engine) then
    filetype = "png"
  end

  return filetype
end

--- Write text to a file
---
--- @param filename string Path to the file
--- @param text string Content to write
local function write_file(filename, text)
  local file = io.open(filename, "w")
  if not file then
    error("Could not open file for writing: " .. filename)
  end
  file:write(text)
  file:close()
end

-- ============================================================================
-- Plotting Engine Functions
-- ============================================================================

--- GraphViz family renderer (generic)
---
--- @param engine string GraphViz engine name (dot, neato, etc.)
--- @param code string GraphViz source code
--- @param filetype string Output file type
--- @param fname string Output file path
--- @return boolean|string Success status or error message
local function graphviz(engine, code, filetype, fname)
  return pandoc.pipe(engine, {"-T" .. filetype, "-o", fname}, code)
end

--- DOT renderer (GraphViz)
local function dot(code, filetype, fname)
  return graphviz("dot", code, filetype, fname)
end

--- Neato renderer (GraphViz)
local function neato(code, filetype, fname)
  return graphviz("neato", code, filetype, fname)
end

--- FDP renderer (GraphViz)
local function fdp(code, filetype, fname)
  return graphviz("fdp", code, filetype, fname)
end

--- SFDP renderer (GraphViz)
local function sfdp(code, filetype, fname)
  return graphviz("sfdp", code, filetype, fname)
end

--- TWOPI renderer (GraphViz)
local function twopi(code, filetype, fname)
  return graphviz("twopi", code, filetype, fname)
end

--- CIRCO renderer (GraphViz)
local function circo(code, filetype, fname)
  return graphviz("circo", code, filetype, fname)
end

--- DITAA renderer (ASCII art diagrams)
---
--- @param code string DITAA source code
--- @param filetype string Output file type
--- @param fname string Output file path
--- @param cname string Source code file path
--- @return boolean|string Success status or error message
local function ditaa(code, filetype, fname, cname)
  write_file(cname, code)
  return pandoc.pipe("ditaa", {cname, fname}, code)
end

--- Goseq renderer (sequence diagrams)
---
--- @param code string Goseq source code
--- @param filetype string Output file type
--- @param fname string Output file path
--- @param cname string Source code file path
--- @return boolean|string Success status or error message
local function goseq(code, filetype, fname, cname)
  write_file(cname, code)
  local svg_name = string.gsub(fname, '.' .. filetype, '.svg')
  local success, img = pandoc.pipe("goseq", {"-o", svg_name, cname}, code)

  -- Convert SVG to requested format if needed
  if filetype ~= 'svg' then
    rsvg_convert(svg_name, fname, filetype)
  end
  return success, img
end

--- A2S renderer (ASCII to SVG)
---
--- @param code string ASCII art source code
--- @param filetype string Output file type
--- @param fname string Output file path
--- @param cname string Source code file path (unused)
--- @return boolean|string Success status or error message
local function a2s(code, filetype, fname, cname)
  local svg_name = string.gsub(fname, '.' .. filetype, '.svg')
  local success, img = pandoc.pipe("a2s", {"-i", "-", "-o", svg_name}, code)

  -- Convert SVG to requested format if needed
  if filetype ~= 'svg' then
    rsvg_convert(svg_name, fname, filetype)
  end
  return success, img
end

--- ABC music notation renderer
---
--- @param code string ABC notation source code
--- @param filetype string Output file type
--- @param fname string Output file path
--- @param cname string Source code file path (unused)
--- @return boolean|string Success status or error message
local function abcm2ps(code, filetype, fname, cname)
  local base_name = string.gsub(fname, '.' .. filetype, '')
  local success, img = pandoc.pipe("abcm2ps", {"-", "-c", "-S", "-E", "-O", base_name}, code)
  
  -- Convert EPS to PDF
  os.execute("epspdf " .. base_name .. "001.eps " .. base_name .. ".pdf")
  
  -- Convert PDF to requested format if needed
  if filetype ~= 'pdf' then
    os.execute("pdftocairo -" .. filetype .. " " .. base_name .. ".pdf " ..
               base_name .. "." .. filetype)
  end

  return success, img
end

--- TikZ renderer (LaTeX graphics)
---
--- @param code string TikZ source code
--- @param filetype string Output file type
--- @param fname string Output file path
--- @param cname string Source code file path (unused)
--- @param package string|nil Additional LaTeX packages
--- @return boolean|string Success status or error message
local function tikz(code, filetype, fname, cname, package)
  local base_name = string.gsub(fname, '.' .. filetype, '')
  local tex_file = base_name .. ".tex"
  local f = io.open(tex_file, 'w')
  if not f then
    error("Could not open TikZ file for writing: " .. tex_file)
  end
  
  f:write("\\documentclass{standalone}\n\\usepackage{tikz}\n")
  if package then
    f:write(package)
  end
  f:write("\n\\begin{document}\n")
  f:write(code)
  f:write("\n\\end{document}\n")
  f:close()

  -- Compile with XeLaTeX
  local success, img = pandoc.pipe("xelatex", {'-output-directory', render_dir, base_name}, '')

  -- Convert PDF to requested format if needed
  if filetype ~= 'pdf' then
    os.execute("pdftocairo -" .. filetype .. " " .. base_name .. ".pdf " ..
               base_name .. "." .. filetype)
  end

  return success, img
end

--- Gnuplot renderer
---
--- @param code string Gnuplot source code
--- @param filetype string Output file type
--- @param fname string Output file path
--- @param cname string Source code file path
--- @return boolean|string Success status or error message
local function gnuplot(code, filetype, fname, cname)
  -- Comment out terminal and output settings in the code (we handle them)
  local processed_code = code
  processed_code = string.gsub(processed_code, '(set ter)', '#%1')
  processed_code = string.gsub(processed_code, '(se t)', "#%1")
  processed_code = string.gsub(processed_code, '(se o)', "#%1")
  processed_code = string.gsub(processed_code, '(set out)', "#%1")

  write_file(cname, processed_code)

  -- Determine terminal type
  local term = filetype
  if filetype == 'png' or filetype == 'pdf' then
    term = filetype .. "cairo"
  end
  
  -- Execute gnuplot with terminal and output settings
  local success, img = pandoc.pipe("gnuplot", {
    "-e",
    "set term " .. term .. " enhanced;set out '" .. fname .. "';",
    cname
  }, code)

  return success, img
end

--- Asymptote renderer
---
--- @param code string Asymptote source code
--- @param filetype string Output file type
--- @param fname string Output file path
--- @param cname string Source code file path (unused)
--- @return boolean|string Success status or error message
local function asy(code, filetype, fname, cname)
  return pandoc.pipe("asy", {"-f", filetype, "-o", fname}, code)
end

--- Map engine name to actual command name
---
--- @param engine string The engine name
--- @return string The actual command name
local function engine_path(engine)
  if engine == "abc" then
    return "abcm2ps"
  elseif engine == "tikz" then
    return "xelatex"
  else
    return engine
  end
end

-- ============================================================================
-- Engine Registry
-- ============================================================================

--- Registry of all supported plotting engines
local valid_engines = {
  dot = dot,
  fdp = fdp,
  sfdp = sfdp,
  twopi = twopi,
  neato = neato,
  circo = circo,
  ditaa = ditaa,
  gnuplot = gnuplot,
  goseq = goseq,
  a2s = a2s,
  asy = asy,
  abc = abcm2ps,
  tikz = tikz,
}

-- ============================================================================
-- Image Rendering
-- ============================================================================

--- Extract and validate engine name from code block
---
--- @param block table The CodeBlock element
--- @return string|nil Engine name if valid, nil otherwise
local function extract_engine(block)
  if not block.attr.classes[1] then
    return nil
  end

  -- Check for "plot:engine" pattern
  if not string.match(block.attr.classes[1], '^plot:.*') then
    return nil
  end

  -- Extract engine name
  local engine = string.gsub(block.attr.classes[1], 'plot:', '')

  -- Check if engine is supported
  if not in_table(table_keys(valid_engines), engine) then
    return nil
  end

  return engine
end

--- Check if engine is available and handle missing engine
---
--- @param engine string The engine name
--- @param block table The CodeBlock element
--- @return boolean True if engine is available, false otherwise
local function check_engine_available(engine, block)
  if which(engine_path(engine)) then
    return true
  end

  -- Engine not available: modify block to show warning
  block.text = "! Note: " .. engine_path(engine) ..
               " not installed ! So I did not render this code\n\n" ..
               block.text
  print("\27[31mPlot Warning: " .. engine_path(engine) .. " not installed!\27[m")
  return false
end

--- Generate file names for rendered image and source code
---
--- @param block table The CodeBlock element
--- @param engine string The engine name
--- @param filetype string The output file type
--- @return string, string Output file path and source code file path
local function generate_file_names(block, engine, filetype)
  local fname, cname

  if block.identifier then
    -- Use identifier for stable file names
    local id_str = block.identifier:gsub('fig:', '', 1)
    fname = render_dir .. "/" .. id_str .. "." .. filetype
    cname = code_dir .. "/" .. id_str .. ".txt"
  else
    -- Use content hash for cacheable file names
    local content_hash = pandoc.sha1(block.text) .. "_" .. engine
    fname = render_dir .. "/" .. content_hash .. "." .. filetype
    cname = code_dir .. "/" .. content_hash .. ".txt"
  end

  return fname, cname
end

--- Render the image using the specified engine
---
--- @param engine string The engine name
--- @param block table The CodeBlock element
--- @param filetype string The output file type
--- @param fname string Output file path
--- @param cname string Source code file path
local function execute_rendering(engine, block, filetype, fname, cname)
  -- Render the image
  local success, img = pcall(valid_engines[engine], block.text, filetype,
                             fname, cname,
                             block.attributes["usepackage"] or nil)

  -- Check if rendering succeeded
  if not success or not file_exists(fname) then
    print("\27[31mPlot Error: " .. engine .. " error!\27[m")
    io.stderr:write(tostring(img))
    io.stderr:write('\n')
    error('Image conversion failed. Aborting.')
  end
end

--- Create image element from rendered file
---
--- @param block table The CodeBlock element
--- @param fname string Output file path
--- @return table The Image element
local function create_image_element(block, fname)
  -- Process caption if provided
  local caption = {}
  local enable_caption = nil
  if block.attributes["caption"] then
    caption = pandoc.read(block.attributes.caption).blocks[1].content
    enable_caption = "fig:"  -- Pandoc hack to enforce caption
  end

  -- Create image object
  local img_obj = pandoc.Image(caption, fname, enable_caption)
  img_obj.attr.identifier = block.attr.identifier

  -- Transfer remaining classes and attributes
  table.remove(block.attr.classes, 1)  -- Remove "plot:engine" class
  img_obj.attr.classes = block.attr.classes
  img_obj.attributes = block.attributes

  -- Transfer "name" attribute if present
  if block.attributes["name"] then
    img_obj.attributes["name"] = block.attributes["name"]
  end

  return img_obj
end

--- Render an image from a code block
---
--- This function processes a code block with a "plot:engine" class and
--- converts it to an image using the specified engine.
---
--- @param block table The CodeBlock element
--- @return table The processed block (Image or original CodeBlock)
local function render_image(block)
  -- Extract and validate engine
  local engine = extract_engine(block)
  if not engine then
    return block
  end

  -- Check if engine is available
  if not check_engine_available(engine, block) then
    return block
  end

  -- Determine file type and generate file names
  local filetype = get_filetype(engine)
  local fname, cname = generate_file_names(block, engine, filetype)

  -- Check cache: if file exists, skip rendering
  if file_exists(fname) then
    print("Plot Cache Hit: " .. fname)
  else
    -- Render the image
    execute_rendering(engine, block, filetype, fname, cname)
  end

  -- Create and return image element
  return create_image_element(block, fname)
end

-- ============================================================================
-- Subfigure Support
-- ============================================================================

--- Group content by subfig attribute
---
--- This function processes Div content and groups CodeBlocks by their subfig
--- attribute, rendering images as it goes.
---
--- @param block table The Div element
--- @return table Table mapping group numbers to content arrays
local function group_by_subfig(block)
  local subfigs = {}
  local current_group = 1
  subfigs[current_group] = {}

  for _, content in pairs(block.content) do
    if content.t == "CodeBlock" and content.attributes["subfig"] ~= nil then
      -- Start new subfigure group
      current_group = tonumber(content.attributes["subfig"]) or 1
      if subfigs[current_group] == nil then
        subfigs[current_group] = {}
      end
      -- Render the code block to an image
      table.insert(subfigs[current_group], render_image(content))
    else
      -- Add to current group
      table.insert(subfigs[current_group], content)
    end
  end

  return subfigs
end

--- Process a single subfigure group
---
--- This function separates images from other content in a group and creates
--- appropriate Para blocks for images and adds other content directly.
---
--- @param group table Array of content items in the group
--- @return table, table Image group Para and array of other content blocks
local function process_subfig_group(group)
  local img_group = pandoc.Para({})
  local para_content = {}

  for _, item in pairs(group) do
    if item.t == "Image" then
      -- Add image with spacing
      table.insert(img_group.content, item)
      table.insert(img_group.content, pandoc.Str("\u{A0}"))  -- Non-breaking space
      table.insert(img_group.content, pandoc.Str("\u{A0}"))
      table.insert(img_group.content, pandoc.SoftBreak())
    else
      table.insert(para_content, item)
    end
  end

  return img_group, para_content
end

--- Process Div blocks containing subfigures
---
--- This function processes Div blocks with "fig:" identifiers that contain
--- multiple code blocks with subfig attributes. It groups them into subfigures.
---
--- @param block table The Div element
--- @return table|nil The processed Div, or nil if unchanged
local function process_div(block)
  -- Check if this is a figure Div
  if not string.match(block.attr.identifier or "", '^fig:.*') then
    return nil
  end

  local new_block = pandoc.Div({})
  new_block.attr.identifier = block.attr.identifier

  -- Group content by subfig attribute
  local subfigs = group_by_subfig(block)

  -- Process each subfigure group
  for _, group in pairs(subfigs) do
    local img_group, para_content = process_subfig_group(group)

    -- Add image group if it has content
    if #img_group.content > 0 then
      table.insert(new_block.content, img_group)
    end

    -- Add other content
    for _, item in pairs(para_content) do
      table.insert(new_block.content, item)
    end
  end

  return new_block
end

--- Process code blocks for rendering
---
--- @param block table The CodeBlock element
--- @return table|nil The processed block, or nil if unchanged
local function process_codeblock(block)
  -- Skip if this is a subfigure (handled by Div processor)
  if block.attributes["subfig"] ~= nil then
    return nil
  end

  local img = render_image(block)
  if img.t == "Image" then
    return pandoc.Para{img}
  else
    return img
  end
end

-- ============================================================================
-- Filter Registration
-- ============================================================================

return {
  {Div = process_div},
  {CodeBlock = process_codeblock},
}
