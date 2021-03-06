#!/usr/bin/perl
use strict;
use warnings;

use feature ':5.10';
use IPC::Run 'run';
use Text::Diff 'diff';
use Carp qw(cluck confess);
use FindBin '$Bin';

use Term::ANSIColor;
my $Nfailed = 0;

my $data_default = <<'EOF';
#!/bin/xxx
# a b c
1 2 3
4 - 6
7 9 -
10 11 12
EOF

my $data_latlon = <<'EOF';
#!/bin/xxx
# lat lon lat2 lon2
37.0597792247 -76.1703387355 37.0602752259 -76.1705049567
37.0598883299 -76.1703577868 37.0604772596 -76.1705748082
37.0599879749 -76.1703966222 37.0605833650 -76.1706010153
37.0600739448 -76.1704347187 37.0606881510 -76.1706390439
37.0601797672 -76.1704662408 37.0607908914 -76.1706712460
EOF

my $data_cubics = <<'EOF';
#!/bin/xxx
# x
1
8
27
64
125
EOF

my $data_specialchars = <<'EOF';
#!/bin/xxx
# PID USER PR NI   VIRT   RES   SHR  S %CPU %MEM  TIME+     COMMAND
25946 dima 20 0    82132 23828   644 S 5.9  1.2  0:01.42 mailalert.pl
27036 dima 20 0  1099844 37772 13600 S 5.9  1.9  1:29.57 mpv
28648 dima 20 0    45292  3464  2812 R 5.9  0.2  0:00.02 top
    1 root 20 0   219992  4708  3088 S 0.0  0.2  1:04.41 systemd
EOF

my $data_hasempty_hascomments = <<'EOF';
#!adsf
# a b c
1 2 3
## zcxv
4 - 6
7 9 -
- - -
EOF

my $data_int_dup = <<'EOF';
# c a c
2 1 a
4 - b
6 5 c
EOF





check( <<'EOF', qw(-p s=b) );
#!/bin/xxx
# s
2
9
11
EOF

check( <<'EOF', qw(-p s=b --noskipempty) );
#!/bin/xxx
# s
2
-
9
11
EOF

check( <<'EOF', qw(--noskipempty), {data => $data_hasempty_hascomments} );
#!adsf
# a b c
1 2 3
## zcxv
4 - 6
7 9 -
- - -
EOF

check( <<'EOF', qw(--skipempty), {data => $data_hasempty_hascomments} );
#!adsf
# a b c
1 2 3
## zcxv
4 - 6
7 9 -
EOF

check( <<'EOF', qw(--noskipempty --skipcomments), {data => $data_hasempty_hascomments} );
# a b c
1 2 3
4 - 6
7 9 -
- - -
EOF

check( <<'EOF', qw(--skipempty --skipcomments), {data => $data_hasempty_hascomments} );
# a b c
1 2 3
4 - 6
7 9 -
EOF

check( <<'EOF', '-p', 's=b,a' );
#!/bin/xxx
# s a
2 1
- 4
9 7
11 10
EOF

check( <<'EOF', '-p', 's=b,a', '--noskipempty');
#!/bin/xxx
# s a
2 1
- 4
9 7
11 10
EOF

check( <<'EOF', qw(-p s=a) );
#!/bin/xxx
# s
1
4
7
10
EOF

check( <<'EOF', qw(-p s=a+1) );
#!/bin/xxx
# s
2
5
8
11
EOF

check( <<'EOF', qw(-p s=a+1) );
#!/bin/xxx
# s
2
5
8
11
EOF

check( <<'EOF', qw(-p .) );
#!/bin/xxx
# a b c
1 2 3
4 - 6
7 9 -
10 11 12
EOF

check( <<'EOF', '-p', 'a,b' );
#!/bin/xxx
# a b
1 2
4 -
7 9
10 11
EOF

check( <<'EOF', qw(-p a -p b) );
#!/bin/xxx
# a b
1 2
4 -
7 9
10 11
EOF

check( <<'EOF', qw(--print a --pick b) );
#!/bin/xxx
# a b
1 2
4 -
7 9
10 11
EOF

check( <<'EOF', qw( -p [ab]) );
#!/bin/xxx
# a b
1 2
4 -
7 9
10 11
EOF

check( <<'EOF', qw(--has a -p .) );
#!/bin/xxx
# a b c
1 2 3
4 - 6
7 9 -
10 11 12
EOF

check( <<'EOF', qw(--has b) );
#!/bin/xxx
# a b c
1 2 3
7 9 -
10 11 12
EOF

check( <<'EOF', qw(--has c -p .) );
#!/bin/xxx
# a b c
1 2 3
4 - 6
10 11 12
EOF

check( <<'EOF', '--has', 'b,c');
#!/bin/xxx
# a b c
1 2 3
10 11 12
EOF

check( <<'EOF', '--has', 'b,c');
#!/bin/xxx
# a b c
1 2 3
10 11 12
EOF

check( <<'EOF', qw(--has b --has c -p .) );
#!/bin/xxx
# a b c
1 2 3
10 11 12
EOF

check( <<'EOF', qw(--has b --has c) );
#!/bin/xxx
# a b c
1 2 3
10 11 12
EOF

check( <<'EOF', qw(--has b --has c -p a) );
#!/bin/xxx
# a
1
10
EOF

check( <<'EOF', qw(-p d=rel(a) -p b -p c --noskipempty));
#!/bin/xxx
# d b c
0 2 3
3 - 6
6 9 -
9 11 12
EOF

check( <<'EOF', qw(rel(a)>6 -p . -p d=rel(a)));
#!/bin/xxx
# a b c d
10 11 12 9
EOF

check( <<'EOF', qw(-p d=rel(a) -p b -p c));
#!/bin/xxx
# d b c
0 2 3
3 - 6
6 9 -
9 11 12
EOF

check( <<'EOF', qw(-p r=rel(a) -p b -p d=diff(a) -p c -p a));
#!/bin/xxx
# r b d c a
0 2 0 3 1
3 - 3 6 4
6 9 3 - 7
9 11 3 12 10
EOF

check( <<'EOF', ['-p', 'r=rel(a),b,c'], [qw(-p r)]);
#!/bin/xxx
# r
0
3
6
9
EOF

check( <<'EOF', ['-p', 'r=rel(a),b,c'], [qw(-p r=rel(r))]);
#!/bin/xxx
# r
0
3
6
9
EOF

check( <<'EOF', ['-p', 'r=rel(a),b,c'], [qw(-p d=diff(r))]);
#!/bin/xxx
# d
0
3
3
3
EOF

check( <<'EOF', '-p', 'd1=diff(x),d2=diff(diff(x))', {data => $data_cubics});
#!/bin/xxx
# d1 d2
0 0
7 7
19 12
37 18
61 24
EOF

check( <<'EOF', qw(--has b -p [ab]) );
#!/bin/xxx
# a b
1 2
7 9
10 11
EOF

check( <<'EOF', ['--has', 'b', '-p', 'da=diff(a),db=diff(b)'], ['db>3'], {language => 'AWK'} );
#!/bin/xxx
# da db
6 7
EOF

check( <<'EOF', ['-p', 'a,r=rel(a)'], ['a<4'], {language => 'AWK'} );
#!/bin/xxx
# a r
1 0
EOF

check( <<'EOF', ['-p', 'a,r=rel(a)'], ['r<4'], {language => 'AWK'} );
#!/bin/xxx
# a r
1 0
4 3
EOF

check( <<'EOF', ['-p', 'r=rel(a),a'], ['a<4'], {language => 'AWK'} );
#!/bin/xxx
# r a
0 1
EOF

check( <<'EOF', ['-p', 'r=rel(a),a'], ['r<4'], {language => 'AWK'} );
#!/bin/xxx
# r a
0 1
3 4
EOF

check( <<'EOF', ['-p', 'r=rel(a),a'], ['--eval', '{print r}'], {language => 'AWK'} );
0
3
6
9
EOF

check( <<'EOF', ['-p', 'r=rel(a),a'], ['--eval', 'say r'], {language => 'perl'} );
0
3
6
9
EOF

check( <<'EOF', 'a>5' );
#!/bin/xxx
# a b c
7 9 -
10 11 12
EOF

check( <<'EOF', qw(a>5 -p c) );
#!/bin/xxx
# c
12
EOF

check( <<'EOF', qw(a>5 --no-skipempty -p c) );
#!/bin/xxx
# c
-
12
EOF

check( <<'EOF', 'a>5', '--eval', '{print a+b}', {language => 'AWK'} );
16
21
EOF

check( <<'EOF', 'a>5', '--function', 'func() { return a + b }', '-p', 'sum=func()', {language => 'AWK'} );
#!/bin/xxx
# sum
16
21
EOF

check( <<'EOF', 'a>5', '--function', 'func(x,y) { return x + y }', '-p', 'sum=func(a,b)', {language => 'AWK'} );
#!/bin/xxx
# sum
16
21
EOF

check( <<'EOF', 'a>5', '--function', 'func { return a + b }', '-p', 'sum=func()', {language => 'perl'} );
#!/bin/xxx
# sum
16
21
EOF

check( <<'EOF', 'a>5', '--function', 'func { my ($x,$y) = @_; return $x + $y }', '-p', 'sum=func(a,b)', {language => 'perl'} );
#!/bin/xxx
# sum
16
21
EOF

check( <<'EOF', 'a>5', '--eval', '{say a+b}', {language => 'perl'} );
16
21
EOF

check( <<'EOF', 'a>5', '--eval', 'my $v = a + b + 2; say $v', {language => 'perl'} );
18
23
EOF

check(<<'EOF', qw(-p M), {data => $data_specialchars});
#!/bin/xxx
# %MEM TIME+ COMMAND
1.2 0:01.42 mailalert.pl
1.9 1:29.57 mpv
0.2 0:00.02 top
0.2 1:04.41 systemd
EOF

check(<<'EOF', '-p', q{s=1 + %CPU,s2=%CPU + 2,s3=TIME+ + 1,s4=1 + TIME+}, {data => $data_specialchars});
#!/bin/xxx
# s s2 s3 s4
6.9 7.9 1 1
6.9 7.9 2 2
6.9 7.9 1 1
1 2 2 2
EOF

# A log with duplicated columns should generally behave normally, if we aren't
# explicitly touching the duplicate columns
check(<<'EOF', qw(1), {data => $data_int_dup});
# c a c
2 1 a
4 - b
6 5 c
EOF

check(<<'EOF', qw(a==1), {data => $data_int_dup});
# c a c
2 1 a
EOF

check('ERROR', qw(c==1), {data => $data_int_dup});

check(<<'EOF', qw(-p a), {data => $data_int_dup});
# a
1
5
EOF

check(<<'EOF', qw(-p a --noskipempty), {data => $data_int_dup});
# a
1
-
5
EOF

check(<<'EOF', qw(-p .), {data => $data_int_dup});
# c a c
2 1 a
4 - b
6 5 c
EOF

check(<<'EOF', qw(-p c), {data => $data_int_dup});
# c c
2 a
4 b
6 c
EOF


check( <<'EOF', qw(-p b) );
#!/bin/xxx
# b
2
9
11
EOF

check( <<'EOF', qw(-p b*) );
#!/bin/xxx
# b
2
9
11
EOF

check('ERROR', qw(-p X*));

# exclusions
check(<<'EOF', '--noskipempty', '-p', '.,!c', {data => $data_int_dup});
# a
1
-
5
EOF

check(<<'EOF', '--noskipempty', '-p', '.,!a', {data => $data_int_dup});
# c c
2 a
4 b
6 c
EOF

check(<<'EOF', '--noskipempty', '-p', '.,!c*', {data => $data_int_dup});
# a
1
-
5
EOF

check(<<'EOF', '--noskipempty', qw(-p !c), {data => $data_int_dup});
# a
1
-
5
EOF

check(<<'EOF', '--noskipempty', qw(-p !a), {data => $data_int_dup});
# c c
2 a
4 b
6 c
EOF

check('ERROR', '--noskipempty', '-p', '.,!.*', {data => $data_int_dup}); # no cols left

check('ERROR', '--noskipempty', '-p', '.,!xxxx', {data => $data_int_dup}); # col not found

check(<<'EOF', '--noskipempty', '-p', 'a,b=a,z=a,![az]', {data => $data_int_dup});
# b
1
-
5
EOF



# # awk and perl write out the data with different precisions, so I test them separately for now
# check( <<'EOF', '-p', 'rel_n(lat),rel_e(lon),rel_n(lat2),rel_e(lon2)', {language => 'AWK', data => $data_latlon} );
# # rel_n(lat) rel_e(lon) rel_n(lat2) rel_e(lon2)
# 0 0 55.1528 -14.7495
# 12.1319 -1.6905 77.6179 -20.9478
# 23.212 -5.13654 89.4163 -23.2732
# 32.7714 -8.51701 101.068 -26.6477
# 44.5383 -11.3141 112.492 -29.5051
# EOF


# check( <<'EOF', '-p', 'rel_n(lat),rel_e(lon),rel_n(lat2),rel_e(lon2)', {language => 'perl', data => $data_latlon} );
# # rel_n(lat) rel_e(lon) rel_n(lat2) rel_e(lon2)
# 0 0 55.1528170494324 -14.7495300237067
# 12.1319447101403 -1.69050470904804 77.6179395005555 -20.9477574245461
# 23.2119631755057 -5.13653865865383 89.4163216701965 -23.2732273896387
# 32.7713799003105 -8.51700679638622 101.06799325373 -26.6476704659731
# 44.5382939050826 -11.3140998289326 112.492204495462 -29.505102855998
# EOF





if($Nfailed == 0 )
{
    say colored(["green"], "All tests passed!");
    exit 0;
}
else
{
    say colored(["red"], "$Nfailed tests failed!");
    exit 1;
}




sub check
{
    # I check stuff twice. Once with perl processing, and again with awk
    # processing

    my ($expected, @args) = @_;

    my @langs;
    my $data;
    if(ref($args[-1]) && ref($args[-1]) eq 'HASH' )
    {
        my $opts = pop @args;
        if($opts->{language})
        {
            push @langs, ($opts->{language} =~ /perl/i ? 1 : 0);
        }
        if($opts->{data})
        {
            $data = $opts->{data};
        }
    }
    if( !@langs )
    {
        @langs = (0,1);
    }
    $data //= $data_default;

  LANGUAGE:
    for my $doperl (@langs)
    {
        # if the arguments are a list of strings, these are simply the args to a
        # filter run. If the're a list of list-refs, then we run the filter
        # multiple times, with the arguments in each list-ref
        if ( !ref $args[0] )
        {
            my @args2 = @args;
            @args = (\@args2);
        }

        # @args is now a list-ref. Each element is a filter operation
        my $in = $data;
        my $out;
        my $err;
        for my $arg (@args)
        {
            my @args_here = @$arg;
            push @args_here, '--perl' if $doperl;

            $out = '';
            my $result =
              run( ["perl",
                    "$Bin/../vnl-filter", @args_here], \$in, \$out, \$err );
            $in = $out;

            if($expected ne 'ERROR' && !$result)
            {
                cluck "Test failed. Expected success, but got failure";
                $Nfailed++;
                next LANGUAGE;
            }
            if($expected eq 'ERROR' && $result)
            {
                cluck "Test failed. Expected failure, but got success";
                $Nfailed++;
                next LANGUAGE;
            }
            if($expected eq 'ERROR' && !$result)
            {
                # successful failure
                next LANGUAGE;
            }

        }

        my $diff = diff(\$expected, \$out);
        if ( length $diff )
        {
            cluck "Test failed when doperl=$doperl; diff: '$diff'";
            $Nfailed++;
        }
    }
}
