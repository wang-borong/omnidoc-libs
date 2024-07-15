-- counts words in a document

local words = 0
local noascii = 0
local ascii_words = 0
local characters = 0
local characters_and_spaces = 0
local process_anyway = false

-- 利用正则表达式分词，匹配中文单词
local function count_noascii(text)
    local count = 0
    for _ in text:gmatch("[%z\194-\244][\128-\191]*") do
        count = count + 1
    end
    return count
end

-- 利用正则表达式分词，匹配英文单词
local function count_ascii_words(text)
    local count = 0
    for _ in text:gmatch("[%a%-%d_]+") do
        count = count + 1
    end
    return count
end

local wordcount = {
  Str = function(el)
    -- we don't count a word if it's entirely punctuation:
    if el.text:match("%P") then
        words = words + 1
    end
    characters = characters + utf8.len(el.text)
    characters_and_spaces = characters_and_spaces + utf8.len(el.text)

    noascii = noascii + count_noascii(el.text)
    ascii_words = ascii_words + count_ascii_words(el.text)
  end,

  Space = function()
    characters_and_spaces = characters_and_spaces + 1
  end,

  Code = function(el)
    local _, n = el.text:gsub("%S+","")
    words = words + n
    local text_nospace = el.text:gsub("%s", "")
    characters = characters + utf8.len(text_nospace)
    characters_and_spaces = characters_and_spaces + utf8.len(el.text)
    noascii = noascii + count_noascii(el.text)
    ascii_words = ascii_words + count_ascii_words(el.text)
  end,

  CodeBlock = function(el)
    local _, n = el.text:gsub("%S+","")
    words = words + n
    local text_nospace = el.text:gsub("%s", "")
    characters = characters + utf8.len(text_nospace)
    characters_and_spaces = characters_and_spaces + utf8.len(el.text)
    noascii = noascii + count_noascii(el.text)
    ascii_words = ascii_words + count_ascii_words(el.text)
  end
}

-- check if the `wordcount` variable is set to `process-anyway`
function Meta(meta)
  if meta.wordcount and (meta.wordcount=="process-anyway"
    or meta.wordcount=="process" or meta.wordcount=="convert") then
    process_anyway = true
  end
end

function Pandoc(el)
  -- skip metadata, just count body:
  pandoc.walk_block(pandoc.Div(el.blocks), wordcount)
  -- print(words .. " words in body")
  -- print(characters .. " characters in body")
  -- print(characters_and_spaces .. " characters in body (including spaces)")
  print('非英文字数：', noascii)
  print('英文字数：', ascii_words)
  print('合计总字数：', noascii + ascii_words)
  if not process_anyway then
    os.exit(0)
  end
end
