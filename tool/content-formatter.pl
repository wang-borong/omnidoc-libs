# NOTE:
#   这个 formatter 不是全能的，它使用 perl 的正则替换，无法顾全所有情况。
#   所以使用该 formatter 后请仔细检查一遍文档，避免错误。

use strict;
use warnings;
use utf8;

use open ':std', ':encoding(UTF-8)';

use Getopt::Long;

my %opts;
GetOptions(\%opts, 'backup', 'markdown', 'semantic', 'symbol'
        ) or die "Bad options\n";

my $file;
foreach $file (@ARGV) {
    format_file($file);
}

sub semantic_format {

    my $line = $_[0];

    sub semantic_fix {
        my $a = $_[0];
        my $b = $_[1];
        my $c = $_[2];
        my $s;
        if ($b =~ /[0-9]+\./) {
            my $l = length($b);
            $s = sprintf("%s%${l}s%s", $a, "", $c);
        } else {
            $s = sprintf("%s%s%s", $a, $b, $c);
        }
        $_[3] =~ s/([。；])([^\n\\\*）])\s*/$1\n$s$2/g;
    }

    # 单句换行
    # markdown list
    if ($line =~ /^(\s*)([0-9]+\.)(\s*)/) {
        semantic_fix($1, $2, $3, $line);
    } elsif ($line =~ /^(\s*)([\*\#\@]+)(\s*)/) { # comment line
        semantic_fix($1, $2, $3, $line);
    } elsif ($line =~ /^(\s*)(\/\*+)(\s*)/) { # c-sytle comment
        semantic_fix($1, $2, $3, $line);
    } elsif ($line =~ /^(\s*)(\-\-+)(\s*)/) { # lua comment
        semantic_fix($1, $2, $3, $line);
    } elsif ($line =~ /^(\s*)(.*)/) {
        semantic_fix($1, "", "", $line);
    }

    return $line;
}

sub symbol_format {

    my $line = $_[0];

    # 如果当前行包含中文，不是 ![ 或数字加“.”开头
    # 或“```”开头，
    # 那么替换常用标点为中文全角标点
    if ($line =~ /.*\p{Han}.*/ and $line !~ /^\s*!\[/
            and $line !~ /^\s*\d{1,}\./ and $line !~ /^\s*\`\`\`/
            and $line !~ /\s*\/\*/ and $line !~ /^\s*\*/
            and $line !~ /^\s*\#/ and $line !~ /^\s*\-\-/
            and $line !~ /^\s*\@/
    ) {
        $line =~ s/([\p{Han} \w\d\\\]]{3,}), ?/$1，/g;
        $line =~ s/([\p{Han} \w\d\\\]]{3,})\. ?/$1。/g;
        $line =~ s/\? ?/？/g;
        $line =~ s/! ?/！/g;
        $line =~ s/: ?/：/g;
        $line =~ s/; ?/；/g;

        # fix miss replacement
        $line =~ s/(\w{2,})。c/$1.c/;
        $line =~ s/([\#\@]\w{3})：/$1:/;
        $line =~ s/([0-9])。([0-9])/$1\.$2/;
    }

    return $line;
}

sub remove_texcmd {

    my $line = $_[0];
    my $texcmd = $_[1]; # can be verb and lstinline

    if ($line =~ /(.*)\\${texcmd}[\{!\|](.*)[\}!\|](.*)/) {
        my $pre = $1;
        my $lst = $2;
        my $post = $3;
        $lst =~ s/\\?_/\\_/g;
    
        $line = sprintf("%s%s%s", $pre, $lst, $post);
    }

    return $line;
}

sub md_format {

    my $line = $_[0];

    $line =~ s/[ \t~]{0,5}\\ref\{(.{5,50})\}[ \t]*/~\\ref\{$1\} /g;
    $line =~ s/[ \t~]*\\verb[\!\|]([ 0-9a-zA-Z_\/\-,\.<>]+)[\!\|][ \t]*/ $1 /g;
    $line =~ s/ *(\[@\w{2,4}:[\w\-]+\]) */ $1 /g; # fig lst eq tbl ref 
    $line =~ s/ *(\[@[\w\-]+\]) */ $1 /g; # bib ref 
    $line =~ s/^ *\[/\[/g;

    # 如果是 ltbr div，那么需要两个结尾空格断行。
    # 但是如果结尾为“。”号，那么会被 common_format 移除，这里需要将其添回。
    if ($line =~ /.*\&.*/) {
      $line =~ s/。$/。  /g;
    }

    return $line;
}

sub tex_format {

    my $line = $_[0];

    # add spaces before and after verb
    $line =~ s/[ \t~]*\\verb[\!\|]([\w\-_\h\.]{3,30})[\!\|][ \t]*/ \\verb\!$1\! /g;

    return $line;
}

sub common_format {

    my $line = $_[0];

    $line =~ s/\t/  /g;

    # replace lstinline with verb
    # $line =~ s/[ \t~]*\\lstinline[\{!]([\w\-_\h\.]{3,30})[\}!][ \t]*/ \\verb\!$1\! /g;

    # 中英文字符之间添加空格
    $line =~ s/(\p{Han})[ \t~]*([(0-9a-zA-Z_\/\-])/$1 $2/g;
    $line =~ s/([0-9a-zA-Z_)\/\-])[ \t~]*(\p{Han})/$1 $2/g;

    # remove space before and after chinese symbols
    $line =~ s/[ \t]*([，。？！：、；…．～￥“”（）「」《》——【】〈〉〔〕‘’])[ \t]*/$1/g;

    $line =~ s/(\d) *- *(\d)/$1 - $2/g;
    $line =~ s/([12][90]\d\d) *- *([01]\d)/$1-$2/g;

    return $line;
}

sub format_file {

    my $file = $_[0];
    my $dstfh;
    open(my $srcfh, '<', $file);
    open($dstfh, '>', "${file}.mod");

    my @lines = <$srcfh>;
    my $line;
    foreach $line (@lines) {

        $line = common_format($line);
        
        $line = tex_format($line);

        if ($opts{markdown}) {
            # fix reference space
            $line = md_format($line);
        }

        # do weak semantic formatting
        if ($opts{semantic}) {
            $line = semantic_format($line);
        }

        if ($opts{symbol}) {
            $line = symbol_format($line);
        }
    }

    # write data lines to destination file
    print $dstfh @lines;

    # close fds
    close($srcfh);
    close($dstfh);

    if (!$opts{backup}) {
        # Delete the original file
        unlink($file);
        # Rename the modified file to the original file name
        rename("${file}.mod", $file);
    }
}
