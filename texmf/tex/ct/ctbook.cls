%%
%% Copyright © 2023 Jason Wang. All Rights Reserved.
%%
%% This is the latex class for writing documents.
%%
%% This document has two options,
%% 1. fontset = {msword, siyuan} to set font family to Microsoft fonts
%%    or to siyuan family fonts
%% 2. linestretch = {100pt, 5cm} to set line stretch to ctex
%% Except the two options, it also support use the ctex's options.

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{ctbook}[2023/09/11 v0.3 a book class derived from ctexbook]

\RequirePackage{kvoptions}
\RequirePackage{etoolbox}
\SetupKeyvalOptions{family=ctbook,prefix=ctbook@,setkeys=\kvsetkeys}
%\newcommand{\wkv}[1]{\kvsetkeys{ctbook}{#1}}

\DeclareStringOption[msword]{fontset}
\DeclareStringOption[10]{linestretch}

\DeclareDefaultOption{\PassOptionsToClass{\CurrentOption}{ctexbook}}

\ProcessKeyvalOptions*\relax

\LoadClass[
  UTF8,
  scheme = chinese,
  heading = true,
  sub4section,
  fontset=\ctbook@fontset,
]{ctexbook}

\ctexset{
  % 设置汉字之间弹性间距的弹性程度。如果有单位，则可以在选项中直接写；
  % 如果是数字，单位则是汉字宽度 \ccwd 的倍数。
  linestretch = \ctbook@linestretch,
  % 使用 sub4section 还需要将计数器设置成 5
  secnumdepth = 5,
  % 将目录层级设为 3
  tocdepth = 3,
}

% 用于临时设置行间距
\RequirePackage{setspace}

% 设置字体
\RequirePackage{fontspec}
% \ifdefstring{\ctbook@fontset}{msword}{
%   % 设置西文字体为Arial，其他字体暂时保持不变
%   \setmainfont{Arial}
%   \setmonofont{Source Code Pro}
% }{
%   \setmainfont{Source Serif Pro}
%   \setsansfont{Source Sans Pro}
%   \setmonofont{Source Code Pro}
% }

% 调整页面大小
\RequirePackage{geometry}

% 用于插入数学公式
\RequirePackage{amsmath,amsthm,amsfonts,amssymb,bm}

% 链接点击相关包
\RequirePackage{hyperref}

% 图表相关
\RequirePackage{float,graphicx,tikz,array}
\floatplacement{figure}{H}

\RequirePackage{tabularx}
\RequirePackage{booktabs}
\RequirePackage{colortbl}

\RequirePackage{biblatex}
\nocite{*}

% 批量设置不同的列表编号
\RequirePackage{enumerate}

% 代码高亮相关
\RequirePackage{listings}
% copied from eisvogel pandoc template
\definecolor{listing-background}{HTML}{F7F7F7}
\definecolor{listing-rule}{HTML}{B3B2B3}
\definecolor{listing-numbers}{HTML}{B3B2B3}
\definecolor{listing-text-color}{HTML}{000000}
\definecolor{listing-keyword}{HTML}{435489}
\definecolor{listing-keyword-2}{HTML}{1284CA} % additional keywords
\definecolor{listing-keyword-3}{HTML}{9137CB} % additional keywords
\definecolor{listing-identifier}{HTML}{435489}
\definecolor{listing-string}{HTML}{00999A}
\definecolor{listing-comment}{HTML}{8E8E8E}
\lstset{ %
  %backgroundcolor=\color{white},   % choose the background color; you must add \usepackage{color} or \usepackage{xcolor}
  backgroundcolor  = \color{listing-background},
  basicstyle=\zihao{-5}\ttfamily,  % the size of the fonts that are used for the code
  %basicstyle = \color{listing-text-color}\linespread{1.0}\zihao{-5}\ttfamily,%
  breakatwhitespace=false,         % sets if automatic breaks should only happen at whitespace
  breaklines=true,                 % sets automatic line breaking
  captionpos=t,                    % sets the caption-position to bottom
  aboveskip        = 0.5em,
  belowskip        = 0.6em,
  abovecaptionskip = 0em,
  belowcaptionskip = 0.5em,
  %commentstyle=\color{gray},      % comment style
  commentstyle = \color{listing-comment},
  escapeinside = {/*@}{@*/},       % Allow LaTeX inside these special comments
  extendedchars=true,              % lets you use non-ASCII characters; for 8-bits encodings only, does not work with UTF-8
  frame=none,                    % adds a frame around the code
  keepspaces=true,                 % keeps spaces in text, useful for keeping indentation of code (possibly needs columns=flexible)
  upquote=true, % 配置成true表示使用英文双引号
  keywordstyle=\color{blue},       % keyword style
  keywordstyle = {\color{listing-keyword}\bfseries},
  keywordstyle = {[2]\color{listing-keyword-2}\bfseries},
  keywordstyle = {[3]\color{listing-keyword-3}\bfseries\itshape},
  numbers=none,                    % where to put the line-numbers; possible values are (none, left, right)
  numbersep=5pt,                   % how far the line-numbers are from the code
  numberstyle=\tiny\color{gray8}, % the style that is used for the line-numbers
  %numberstyle = \color{listing-numbers},
  rulecolor=\color{black},         % if not set, the frame-color may be changed on line-breaks within not-black text (e.g. comments (green here))
  %rulecolor = \color{listing-rule},
  showspaces=false,                % show spaces everywhere adding particular underscores; it overrides 'showstringspaces'
  showstringspaces=false,          % underline spaces within strings only
  showtabs=false,                  % show tabs within strings adding particular underscores
  stepnumber=2,                    % the step between two line-numbers. If it's 1, each line will be numbered
  identifierstyle = \color{listing-identifier},
  stringstyle=\color{listing-string},     % string literal style
  tabsize=2,                       % sets default tabsize to 2 spaces
  % title=\lstname,                  % show the filename of files included with \lstinputlisting; also try caption instead of title
  %xleftmargin=2em,                % 设置左侧缩进为两个字符的宽度
  literate         =
  {á}{{\'a}}1 {é}{{\'e}}1 {í}{{\'i}}1 {ó}{{\'o}}1 {ú}{{\'u}}1
  {Á}{{\'A}}1 {É}{{\'E}}1 {Í}{{\'I}}1 {Ó}{{\'O}}1 {Ú}{{\'U}}1
  {à}{{\`a}}1 {è}{{\`e}}1 {ì}{{\`i}}1 {ò}{{\`o}}1 {ù}{{\`u}}1
  {À}{{\`A}}1 {È}{{\`E}}1 {Ì}{{\`I}}1 {Ò}{{\`O}}1 {Ù}{{\`U}}1
  {ä}{{\"a}}1 {ë}{{\"e}}1 {ï}{{\"i}}1 {ö}{{\"o}}1 {ü}{{\"u}}1
  {Ä}{{\"A}}1 {Ë}{{\"E}}1 {Ï}{{\"I}}1 {Ö}{{\"O}}1 {Ü}{{\"U}}1
  {â}{{\^a}}1 {ê}{{\^e}}1 {î}{{\^i}}1 {ô}{{\^o}}1 {û}{{\^u}}1
  {Â}{{\^A}}1 {Ê}{{\^E}}1 {Î}{{\^I}}1 {Ô}{{\^O}}1 {Û}{{\^U}}1
  {œ}{{\oe}}1 {Œ}{{\OE}}1 {æ}{{\ae}}1 {Æ}{{\AE}}1 {ß}{{\ss}}1
  {ç}{{\c c}}1 {Ç}{{\c C}}1 {ø}{{\o}}1 {å}{{\r a}}1 {Å}{{\r A}}1
  {€}{{\EUR}}1 {£}{{\pounds}}1 {«}{{\guillemotleft}}1
  {»}{{\guillemotright}}1 {ñ}{{\~n}}1 {Ñ}{{\~N}}1 {¿}{{?`}}1
  {…}{{\ldots}}1 {≥}{{>=}}1 {≤}{{<=}}1 {„}{{\glqq}}1 {“}{{\grqq}}1
  {”}{{''}}1
}

% graphics path
\graphicspath{
  {./diagram/}
  {./diagrams/}
  {./figure/}
  {./figures/}
  {./image/}
  {./images/}
  {./graphics/}
  {./graphic/}
  {./pictures/}
  {./picture/}
}

\endinput
