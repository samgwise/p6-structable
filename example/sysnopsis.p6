#! /usr/bin/env perl6
use Structable;

# Define the structure of a record
my $struct = struct-def
    (struct-int    'id_weight'),
    (struct-str    'name_subject'),
    (struct-rat    'weight_subject'),
    (struct-date   'date_measure');

# Conform an acceptable Map to the given structure
say conform($struct,
    { id_weight         => 1
    , name_subject      => 'Foo'
    , weight_subject    => 3.21
    , date_measure      => '2019-01-25'
    }
).ok("Error conforming to struct.").perl;
# output ${:date_measure(Date.new(2019,1,25)), :id_weight(1), :name_subject("Foo"), :weight_subject(3.21)}

# A bad Map of values, something is missing...
{
    my $result = conform($struct,
        { not_the_id        => 2
        , name_subject      => 'Bar'
        , weight_subject    => 1.23
        , date_measure      => '2019-01-25'
        }
    );

    given $result {
        when .is-err {
            .error.say
        }
    }
}
# output: Unable to find value for 'id_weight', keys provided were: 'not_the_id', 'date_measure', 'name_subject', 'weight_subject'

# A good map after some coercion
say conform($struct,
    { id_weight         => "3" #Now it's an Str, just like you commonly find being returned from a parsed JSON document
    , name_subject      => 'Baz'
    , weight_subject    => "7.65"
    , date_measure      => '2019-01-25'
    , Something_extra   => False
    }
).ok("Error conforming to struct").perl;
# output: ${:date_measure(Date.new(2019,1,25)), :id_weight(3), :name_subject("Baz"), :weight_subject(7.65)}
# The conformed values have been coerced into their specified types

# Converting complex types back to a simple structure
say simplify($struct,
    { id_weight         => 3
    , name_subject      => 'Baz'
    , weight_subject    => 7.65
    , date_measure      => Date.new('2019-01-25')
    }
).ok("Error performing simplification with struct").perl;
# output: ${:date_measure("2019-01-25"), :id_weight(3), :name_subject("Baz"), :weight_subject(7.65)}
# The conformed values have been coerced into their specified types
