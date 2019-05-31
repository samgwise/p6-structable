unit module Structable:ver<0.0.3>;
use Result;

=begin pod

=head1 NAME

Structable - Runtime validation of associative datastructures

=head1 SYNOPSIS

=begin code

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
).ok("Err conforming to struct.").perl;
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
).ok("Err conforming to struct").perl;
# output: ${:date_measure(Date.new(2019,1,25)), :id_weight(3), :name_subject("Baz"), :weight_subject(7.65)}
# The conformed values have been coerced into their specified types

# Converting complex types back to a simple structure
say simplify($struct,
    { id_weight         => 3
    , name_subject      => 'Baz'
    , weight_subject    => 7.65
    , date_measure      => Date.new('2019-01-25')
    }
).ok("Err performing simplification with struct").perl;
# output: ${:date_measure("2019-01-25"), :id_weight(3), :name_subject("Baz"), :weight_subject(7.65)}
# The conformed values have been coerced into their specified types
=end code

=head1 DESCRIPTION

The Structable module provides a mechanism for defining an ordered and typed data defenition.

Validating input like JSON is often a tedious task, howevver with Structable you can create concise definitions which you can apply at runtime.
If the input is valid (perhaps with a bit of coercion) then the conformed data will be returned in a Result::Ok object and if there was something wrong a Result::Err will be returned with a helpful error message.
This means that you can use conform operations in a stream of values instead of resorting to try/catch constructs to handle your validation errors.

The struct defenition also defines an order, so by grabing a list of keys you can easily iterate over values in a conformed Map in the order you specified.

=head2 Custom types

If you need more types than those bundled in this module you can add your own! All members of a Strucatable::Struct are Structable::Type[T], a parametric role. Simply pass your type as the role's type parameter and away you go.

=head2 Caveats

Although this module helps provide assurances about the data you are injesting it has not yet been audited and tested to provide any assurances regarding security. Data from an unstrusted source may still be untrustworthy after passing through a conform step provided by this module. Particular caution should be given to the size of payload you are conforming there are no inbuilt mechanisims to prevent this style of abuse in this module.

=head1 AUTHOR

Sam Gillespie <samgwise@gmail.com>

=head1 COPYRIGHT AND LICENCE

Copyright 2018 Sam Gillespie

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

#! A wrapper for the type system
our role Type[::T] {
    has Str:D       $.name is required;
    has Bool        $.optional = False;
    has Callable    $.coercion;
    has Callable    $.to-simple;

    method type-check($obj) {
        $obj ~~ T
    }

    #! If a coercion is defined for this type apply it, else pass value through as an OK
    method coerce($val --> Result::Any) {
        return $!coercion($val) if $!coercion.defined;
        Ok $val
    }

    #! If a to-simple transform is provided for this type apply it, else pass the value through as an OK
    method simplify($val --> Result::Any) {
        return $!to-simple($val) if $!to-simple.defined;
        Ok $val
    }

    method type() { T }
}

# TODO MaybeType - A MaybeType allows for generic wrapping of types such that they are not returned included on validation error. This may be useful for handling empty lists and maps which vary a lot in their serielised representations. However, error reporting may be a little tougher with this type.
# TODO NestedType - A struct of structs would be really cool to have.
# TODO ListType - A list of structs.
# TODO MapType - An associative map of structs, probably Str key to struct is acceptable although Int wouldn't be too hard either.
# # TODO UnionType - Functional style type unions eg List of [A or B or C]

#! A structure of Type roles
our class Struct {
    has List $.structure is required; #rely on struct-def to check params

    method keys( --> Seq) {
        $!structure.map( *.name )
    }
}

#! Sugar for defining a Struct
our sub struct-def(+@members) is export {
    #= A factory for defining a new C<Struct> defenition.
    #= Each argument must be a C<Structable::Type> and is checked on execution of this function.
    Struct.new:
        :structure(
            |(gather for @members {
                when Type { .take }
                default { warn "Expected { Type.What.Perl } in struct-def but recieved { .WHAT.perl }. Skipping bad member-def" }
            })
        )
}

#! filter a map according to our struct
our sub conform(Struct $s, Map $m --> Result::Any) is export {
    #= This subroutine attempts to conform a Map (such as a Hash) to a given struct.
    #= The outcome is returned as a C<Result> object.
    #= A C<Result::Ok> holds a filtered version of a hash which adhears to the given struct.
    #= A C<Result::Err> represents an error and holds an error message describing why the given Map is not conformant to the given Struct.
    Ok %(gather for $s.structure.values -> $elem {
        if $m{$elem.name}:exists {
            my $coerced = $elem.coerce($m{$elem.name});
            return Err "Err coercing '{ $elem.name }': { $coerced.gist }" if $coerced.is-err;
            my $value = $coerced.ok("Err obtaining coercion");

            if $elem.type-check($value) {
                take $elem.name => $value
            }
            else {
                return Err "Type check failed for '{ $elem.name }', expected { $elem.type.WHAT.perl } but received { $m{$elem.name}.WHAT.perl }"
            }
        }
        else {
             unless $elem.optional {
                return Err "Unable to find value for '{ $elem.name }', keys provided were: '{ $m.keys.join("', '") }'"
            }
        }
    })
}
#" fix syntax highlighting in some broken editors...

#
# Sugar for our type wrappers
#

our sub str-to-int($val --> Result::Any) {
    #= A simple coercer for mapping a Str of Int to Int
    #= If you can call Int on it, it'll be acceptable as an Int.
    #= This routine is package scoped and not exported when used.
    return Ok $val if $val ~~ Int;
    try return Ok $val.Int if $val ~~ Str;
    Err "Unable to coerce { $val.WHAT.perl } to Int";
}

our sub str-to-rat($val --> Result::Any) {
    #= A simple coercer for mapping a Str of Rat to Rat
    #= If you can call Int on it, it'll be acceptable as an Int.
    #= This routine is package scoped and not exported when used.
    return Ok $val if $val ~~ Rat;
    try return Ok $val.Rat if $val ~~ Str;
    Err "Unable to coerce { $val.WHAT.perl } to Rat";
}

our sub struct-int(Str:D $name, Bool :$optional = False) is export {
    #= A factory for creating a struct element of type Int.
    #= By default this Type element will try and coerce Str values to Int.
    Type[Int].new(:$name :$optional :coercion(&str-to-int))
}

our sub struct-str(Str:D $name, Bool :$optional = False) is export {
    #= A factory for creating a struct element of type Str
    #= No coercion behaviours are defined for this Type
    Type[Str:D].new(:$name :$optional)
}

our sub struct-rat(Str:D $name, Bool :$optional = False) is export {
    #= A factory for creating a struct element of type Rat.
    #= By default this Type element will try and coerce Str values to Rat.
    Type[Rat].new(:$name :$optional :coercion(&str-to-rat))
}

our sub str-to-date($val --> Result::Any) {
    #= A simple coercer for mapping a Str containing a date string to a Date object
    #= This routine is package scoped and not exported when used.
    return Ok $val if $val ~~ Date;
    try return Ok Date.new($val) if $val ~~ Str;
    Err "Unable to coerce { $val.WHAT.perl } to Date";
}

our sub struct-date(Str:D $name, Bool :$optional = False) is export {
    #= A factory for creating a struct element of type Date.
    #= Coerces date strings to Dat objects according to inbuild Date object behaviour.
    Type[Date].new(:$name, :$optional, :coercion(&str-to-date), :to-simple(&any-to-str))
}

our sub str-to-datetime($val --> Result::Any) {
    #= A simple coercer for mapping a Str containing an ISO time stamp string to a DateTime object
    #= This routine is package scoped and not exported when used.
    return Ok $val if $val ~~ Date;
    try return Ok DateTime.new($val) if $val ~~ Str;
    Err "Unable to coerce { $val.WHAT.perl } to Date";
}

our sub struct-datetime(Str:D $name, Bool :$optional = False) is export {
    #= A factory for creating a struct element of type DateTime.
    #= Coerces date strings to Dat objects according to inbuild Date object behaviour.
    Type[DateTime].new(:$name, :$optional, :coercion(&str-to-datetime), :to-simple(&any-to-str))
}

#
# Struct simplification functions
# Reverses conform function coercions where sensible
#

our sub any-to-str($val --> Result::Any) {
    #= A basic simplifier which calls the .Str method to perform simplification
    #= This routine is package scoped and not exported when used.
    try return Ok $val.Str;
    Err "Unable to simplify { $val.WHAT.perl } to Str, does it impliment .Str?"

}

our sub simplify(Struct:D $s, Map:D $m --> Result::Any) is export {
    #= Pack a given map according to a given struct.
    #= This function is the complement of conform and facilitates packing a map down to a simple map, ready for serialisation to a format such as JSON.
    Ok %(gather for $s.structure.values -> $elem {
        if $m{$elem.name}:exists {
            my $value = $m{$elem.name};
            if $elem.type-check($value) {
                my $simplified = $elem.simplify($value);
                return Err "Err attempting to simplify '{ $elem.name }': { $simplified.gist }" if $simplified.is-err;
            
                take $elem.name => $simplified.ok("Err obtaining simplification");
            }
            else {
                return Err "Type check failed for '{ $elem.name }', expected { $elem.type.WHAT.perl } but received { $m{$elem.name}.WHAT.perl }"
            }
        }
        else {
             unless $elem.optional {
                return Err "Unable to find value for '{ $elem.name }', keys provided were: '{ $m.keys.join("', '") }'"
            }
        }
    })
}
