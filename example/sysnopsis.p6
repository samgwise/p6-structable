#! /usr/bin/env perl6
use Structable;

my $struct = struct-def
    (struct-int,    'id_weight'),
    (struct-str,    'name_subject'),
    (struct-rat,    'weight_subject'),
    (struct-date,   'date_measure');

# An acceptable Map
say conform($struct,
    { id_weight         => 1
    , name_subject      => 'Foo'
    , wieght_subject    => 3.21
    , date_measure      => '2019-01-25'
    }
).WHAT.perl;
# output Result::OK

# A bad Map of values, something is missing
say conform($struct,
    { not_the_id        => 2
    , name_subject      => 'Bar'
    , weight_subject    => 1.23
    , date_measure      => '2019-01-25'
    }
).msg;
# output:

# A good map after some coercion
say conform($struct,
    { id_weight         => "3" #Now it's an Str, just like you commonly find being returned from a parsed JSON document
    , name_subject      => 'Baz'
    , weight_subject    => "7.65"
    , date_measure      => '2019-01-25'
    }
).ok("").perl;
# The conformed values have been coerced into their specified types
