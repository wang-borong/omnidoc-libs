use strict;
use warnings;

use Getopt::Long;

# parse options 
my %opts;
GetOptions(\%opts, 'file=s',
    'es', 's=i', 'e=i'
) or die "Bad options\n";

# open file
my $file = $opts{file};
if (!$file) {
    die "No file specified!\n"
}
open(my $srcfh, '<', $file) or die "Failed to open $file: $!";

# handle file contents with options
add_cont(1);
handle_content($srcfh);
add_cont(0);

# close file
close($srcfh);

# functions
# handle_content($srcfh)
sub handle_content {
    # my @pars = @_;
    my $srcfh = $_[0];

    my @lines = <$srcfh>;
    my $linen = @lines;

    my $sline = $opts{s} // 1;
    my $eline = $opts{e} // $linen;

    my $linec = 1;
    while (my $line = shift(@lines)) {
        if ($linec >= $sline && $linec <= $eline) {
            if (!$opts{es}) {
                next if ($line eq "" || $line =~ /^\s+$/);
            }
            next if ($line =~ /\s*%/);
            $line =~ s/_/\\_/g;
            $line =~ s/#/\\#/g;
            $line =~ s/\&/\\\&/g;
            # change line by options
            if ($opts{lt}) {
                # change the line
                $line =~ s/: / \& /;
                $line =~ s/： */ \& /;
                $line =~ s/ - / \& /;
                $line =~ s/(.+)$/\& $1\\\\\n\\hline/;
                $line =~ s/: /，/g;

                $line =~ s/\& ([\w\b\-_\/]+)\/([\w\b\-_]+)(\.[cS])/\\SetCell\[r=\]\{c\} $1 \& $2$3/;
            } elsif ($opts{ll}) {
                $line =~ s/^\(\d+\)\s*//;
                $line =~ s/^\d+\)\s*//;
                $line =~ s/^\d+）\s*//;
                $line =~ s/^\d+\.\s*//;
                $line =~ s/^\d+．\s*//;
                $line =~ s/^\d+、\s*//;
                $line =~ s/^(.*)/  \\item $1/;
            } elsif ($opts{es}) {

                #print "\n"
            }

            print $line;
        }
        $linec++;
    }
}
