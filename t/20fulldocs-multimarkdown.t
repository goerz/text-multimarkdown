use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use List::MoreUtils qw(uniq);
use File::Slurp qw(slurp);

### Generate difftest subroutine, pretty prints diffs if you have Text::Diff, use uses
### Test::More::is otherwise.

eval {
    require Text::Diff;
};
if (!$@) {
    *difftest = sub {
        my ($got, $expected, $testname) = @_;
        if ($got eq $expected) {
            pass($testname);
            return;
        }
        print "=" x 80 . "\nDIFFERENCES: + = processed version from .text, - = template from .html\n";
        print Text::Diff::diff(\$expected => \$got, { STYLE => "Unified" }) . "\n";
        fail($testname);
    };
}
else {
    warn("Install Text::Diff for more helpful failure message! ($@)");
    *difftest = \&Test::More::is;
}

### Actual code for this test - unless(caller) stops it
### being run when this file is required by other tests

unless (caller) {
    my $docsdir = "$Bin/docs-multimarkdown";
    my @files = get_files($docsdir);

    plan tests => scalar(@files) + 1;

    use_ok('Text::MultiMarkdown');

    my $m = Text::MultiMarkdown->new(
        use_metadata => 0, # FIXME - this should not be required!
    );

    run_tests($m, $docsdir, @files);
}

sub get_files {
    my ($docsdir) = @_;
    my $DH;
    opendir($DH, $docsdir) or die("Could not open $docsdir");
    my @files = uniq map { s/\.(html|text)$// ? $_ : (); } readdir($DH);
    closedir($DH);
    return @files;
}

sub run_tests {
    my ($m, $docsdir, @files) = @_;
    foreach my $test (@files) {
        my ($input, $output);
        eval {
            $output = slurp("$docsdir/$test.html");
            $input  = slurp("$docsdir/$test.text");
        };
        if ($@) {
            fail("1 part of test file not found: $@");
            next;
        }
        $output =~ s/\s+\z//; # trim trailing whitespace
        my $processed = $m->markdown($input);
        $processed =~ s/\s+\z//; # trim trailing whitespace
    
        difftest($processed, $output, "Docs test: $test");
    }
}

1;