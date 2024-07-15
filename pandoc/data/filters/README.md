## Filters 使用

### include-code-files.lua

```sh
pandoc --listings --lua-filter=include-code-files.lua test.md -o test.tex
```

#### Including Files

The simplest way to use this filter is to include an entire file:

    ```{include="hello.c"}
    ```

You can still use other attributes, and classes, to control the code blocks:

    ```{.c include="hello.c" numberLines}
    ```

#### Ranges

If you want to include a specific range of lines, use `startLine` and `endLine`:

    ```{.c include="hello.c" startLine=35 endLine=80}
    ```

`start-line` and `end-line` alternatives are also recognized.

#### Dedent

Using the `dedent` attribute, you can have whitespaces removed on each line,
where possible (non-whitespace character will not be removed even if they occur
in the dedent area).

    ```{.c include="hello.c" dedent=4}
    ```

#### Line Numbers

If you include the `numberLines` class in your code block, and use `include`,
the `startFrom` attribute will be added with respect to the included code's
location in the source file.

    ```{include="hello.c" startLine=35 endLine=80 .numberLines}
    ```

### include-files.lua

#### Usage

Use a special code block with class `include` to include files of the same
format as the input. Each code line is treated as the filename of a file,
parsed, and the result is added to the document.

Metadata from included files is discarded.

##### Shifting Headings

The default is to include the subdocuments unchanged, but it can be convenient
to modify the level of headers; a top-level header in an included file should be
a second or third-level header in the final document.

**Manual shifting**

Use the `shift-heading-level-by` attribute to control header shifting.

**Automatic shifting**

1. Add metadata `-M include-auto` to enable automatic shifting.
2. Do not specify `shift-heading-level-by`
3. It will be inferred to the last heading level encountered

_Example_ :

````md
# Title f

This is `file-f.md`.

## Subtitle f

```{.include} >> equivalent to {.include shift-heading-level-by=2}
file-a.md
```

```{.include shift-heading-level-by=1} >> force shift to be 1
file-a.md
```
````

##### Comments

Comment lines can be added in the include block by beginning a line with two
`//` characters.

##### Different formats

Files are assumed to be written in Markdown, but sometimes one will want to
include files written in a different format. An alternative format can be
specified via the `format` attribute. Only plain-text formats are accepted.

##### Recursive transclusion

Included files can in turn include other files. Note that all filenames must be
relative to the directory from which they are included. I.e., if a file `a/b.md`
is included in the main document, and another file `a/b/c.md` should be included
from `a/b.md`, then the relative path from `a/b.md` must be used, in this case
`b/c.md`. The full relative path will be automatically generated in the final
document. The same goes for image paths and codeblock file paths using the
`include-code-files` filter.
