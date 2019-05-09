#! /usr/bin/env perl6
use v6.c;
use Test;

use-ok 'Structable';

use Structable;

#! check a type defenition against a variety of input values
sub type-table-test(Structable::Type $type, @tests) {
    for @tests -> ($value, $result) {
        is $type.type-check($value), $result, "{ $type.WHAT.perl } { $result ?? 'accepts' !! 'rejects' } { $value.WHAT.perl }";
    }
}

type-table-test struct-int('test-int'), (
    (1, True),
    (Int, True),
    (int, True),
    (Numeric, False),
    (1/1, False),
    (Any, False),
    ("String", False),
);

# Check str to int coercion
is struct-int('coercion test').coerce('1234').is-ok, True, "Str to Int coercion";

type-table-test struct-str('test-str'), (
    (1, False),
    (Str, False),
    (1/1, False),
    (Any, False),
    ("Test String", True),
);

type-table-test struct-rat('test-rat'), (
    (1, False),
    (Str, False),
    (1/1, True),
    (Any, False),
    ("String", False),
    (Rat, True),
    (Numeric, False),
);

type-table-test struct-date('test-date'), (
    (1, False),
    (Str, False),
    (1/1, False),
    (Any, False),
    ("String", False),
    (Rat, False),
    (Numeric, False),
    # See coercion tests ('2019-02-04', True), # ISO reversed form
    (now.Date, True),       # Date object is also acceptable
    (now.DateTime, False),  # DateTime object is rejected
);

# check coercions
is struct-date('coercion test').coerce('2019-02-06').is-ok, True, "Str to Date coercion (date string)";
is struct-date('coercion test').coerce('2019-02-06T08:15:23').is-ok, False, "Str to DateTime coercion (ISO 8601 datetime string)";

type-table-test struct-datetime('test-datetime'), (
    (1, False),
    (Str, False),
    (1/1, False),
    (Any, False),
    ("String", False),
    (Rat, False),
    (Numeric, False),
    # See coercion tests ('2019-02-04T08:15:23', True), # ISO 8601
    (now.Date, False),       # Date object is not acceptable
    (now.DateTime, True),       # DateTime object is also acceptable
);

# check coercions
is struct-datetime('coercion test').coerce('2019-02-06').is-ok, False, "Str to DateTime coercion (date string)";
is struct-datetime('coercion test').coerce('2019-02-06T08:15:23').is-ok, True, "Str to DateTime coercion (ISO 8601 datetime string)";
is struct-datetime('coercion test').coerce('2019-02-06T08:15:23+1100').is-ok, True, "Str to DateTime coercion (RFC 3339 datetime string)";


my $struct = struct-def
    (struct-int     'id_component', :optional),
    (struct-str     'name_component');

my %something-from-json = %(
    :id_component(1),
    :name_component<SomeComponenent>
);

my $obj = conform $struct, %something-from-json;

is $obj.is-ok, True, "map conformed ok";
$obj .= ok("Error unwrapping conformed map");

is-deeply $obj, %something-from-json, "conformed map equals original";

is $obj{$struct.keys}.all.so, True, "Values in conformed object defined";

my %something-bad-from-json = %(
    :id_component(1),
    :not_name_component<SomeComponenent>
);

with conform $struct, %something-bad-from-json {
  fail "bad results from conform should not pass through with";
}
else {
  pass "with catches bad conform results"
}

my %something-without-optional = %(
    :name_component<SomeNewComponenent>
);

is conform($struct, %something-without-optional).so, True, "conform ok without optional param";

done-testing
