use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

require "$Bin/20fulldocs-multimarkdown.t";

my $docsdir = "$Bin/docs-markdown";
my @files = get_files($docsdir);

plan tests => scalar(@files) + 1;

use_ok('Text::MultiMarkdown');

my $m = Text::MultiMarkdown->new(
    use_metadata => 0,
    heading_ids  => 0, # Remove MultiMarkdown behavior change in <hX> tags.
);

{
    local $TODO = 'heading_ids setting has not been implemented yet';
    run_tests($m, $docsdir, @files);
};