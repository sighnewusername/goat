#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;

sub pretty;

sub add_test;
sub add_test_fixture;

sub dump_db;

my %test_db;

while (<>) {
    if (m/^void\s+(test_[A-Za-z0-9_]+)\s*\(\s*void\s+\*\*\s*state\s*\)/) {
        add_test(\%test_db, $1);
    }
    elsif (m/^int\s+(setup_[A-Za-z0-9_]+)\s*\(\s*void\s+\*\*\s*state\s*\)/) {
        add_test_fixture(\%test_db, $1);
    }
    elsif (m/^int\s+(teardown_[A-Za-z0-9_]+)\s*\(\s*void\s+\*\*\s*state\s*\)/) {
        add_test_fixture(\%test_db, $1);
    }
    elsif (m/^int\s+(test_setup)\s*\(\s*void\s+\*\*\s*state\s*\)/) {
        add_test_fixture(\%test_db, $1);
    }
    elsif (m/^int\s+(test_teardown)\s*\(\s*void\s+\*\*\s*state\s*\)/) {
        add_test_fixture(\%test_db, $1);
    }
    elsif (m/^int\s+(group_setup)\s*\(\s*void\s+\*\*\s*state\s*\)/) {
        add_test_fixture(\%test_db, $1);
    }
    elsif (m/^int\s+(group_teardown)\s*\(\s*void\s+\*\*\s*state\s*\)/) {
        add_test_fixture(\%test_db, $1);
    }
    elsif (m/^\s*#include\s*"cmocka\/main\.c"/) {
        dump_db(\%test_db);
    }

    print;
}

exit 0;

sub pretty {
    my ($str) = @_;

    # throw away 'test_' prefix
    $str =~ s/^(?:test|setup|teardown)_//;

    # replace single underscores with spaces
    $str =~ s/(?<!_)_(?!_)/ /g;

    # replace double underscores with singles
    $str =~ s/(?<!_)__(?!_)/_/g;

    # replace triple underscores with spaced hyphen
    $str =~ s/(?<!_)___(?!_)/ - /g;

    return $str;
}

sub add_test {
    my ($db, $funcname) = @_;

    push @{$db->{tests}}, {
        name => pretty($funcname),
        func => $funcname,
    };
}

sub add_test_fixture {
    my ($db, $funcname) = @_;

    if ($funcname =~ m/^(test|group)_(setup|teardown)$/) {
        $db->{fixtures}->{$funcname} = $funcname;
    }
    elsif ($funcname =~ m/^(setup|teardown)_/) {
        $db->{fixtures}->{pretty $funcname}->{$1} = $funcname;
    }
    else {
        print STDERR "add_text_fixture: didn't expect get here: $funcname\n";
    }
}

sub dump_db {
    my ($db) = @_;

    print "\n";
    print "/****************************************************************************/\n";
    print "/* generated by $0 */\n";
    print "\n";
    print "const TestGroup test_group = {\n";
    print "\tgroup_name,\n";

    my $group_setup = $db->{fixtures}->{group_setup} || "NULL";
    print "\t$group_setup,\n";

    my $group_teardown = $db->{fixtures}->{group_teardown} || "NULL";
    print "\t$group_teardown,\n";

    print "\t" . scalar @{$db->{tests}} . ",\n";

    print "\t{\n";
    foreach my $test (@{$db->{tests}}) {
        print "\t\t{ ";
        print qq{"$test->{name}", };
        print qq{$test->{func}, };

        my $setup = $db->{fixtures}->{$test->{name}}->{setup} ||
                    $db->{fixtures}->{test_setup} ||
                    'NULL';

        print qq{$setup, };

        my $teardown = $db->{fixtures}->{$test->{name}}->{teardown} ||
                    $db->{fixtures}->{test_teardown} ||
                    'NULL';

        print qq{$teardown, };

        print " },\n";
    }
    print "\t},\n";

    print "};\n";
    print "/****************************************************************************/\n";
    print "\n";

#    print STDERR Dumper $db;
}
