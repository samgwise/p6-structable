[![Build Status](https://travis-ci.org/samgwise/p6-structable.svg?branch=master)](https://travis-ci.org/samgwise/p6-structable)

NAME
====

Structable - Runtime validation of associative datastructures

SYNOPSIS
========

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

DESCRIPTION
===========

The Structable module provides a mechanism for defining an ordered and typed data definition.

Validating input like JSON is often a tedious task, however with Structable you can create concise definitions which you can apply at runtime. If the input is valid (perhaps with a bit of coercion) then the conformed data will be returned in a Result::Ok object and if there was something wrong, a Result::Err will be returned with a helpful error message. This means that you can use conform operations in a stream of values instead of resorting to try/catch constructs to handle your validation errors.

The struct definition also defines an order, so by grabbing a list of keys you can easily iterate over values in a conformed Map in a uniformly specified order.

Custom types
------------

If you need more types than those bundled in this module you can add your own! All members of a Strucatable::Struct are Structable::Type[T], a parametric role. Simply pass your type as the role's type parameter and away you go.

Caveats
-------

Although this module helps provide assurances about the data you are injesting it has not yet been audited and tested to provide any assurances regarding security. Data from an unstrusted source may still be untrustworthy after passing through a conform step provided by this module. Particular caution should be given to the size of payload you are conforming, there are no inbuilt mechanisims to prevent this style of abuse in this module.

AUTHOR
======

Sam Gillespie <samgwise@gmail.com>

COPYRIGHT AND LICENCE
=====================

Copyright 2018 Sam Gillespie

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

### sub struct-def

```raku
sub struct-def(
    +@members
) returns Mu
```

A factory for defining a new C<Struct> defenition. Each argument must be a C<Structable::Type> and is checked on execution of this function.

### sub conform

```raku
sub conform(
    Structable::Struct:D $s,
    Map:D $m
) returns Result::Any
```

This subroutine attempts to conform a Map (such as a Hash) to a given struct. The outcome is returned as a C<Result> object. A C<Result::Ok> holds a filtered version of a hash which adhears to the given struct. A C<Result::Err> represents an error and holds an error message describing why the given Map is not conformant to the given Struct.

### sub str-to-int

```raku
sub str-to-int(
    $val
) returns Result::Any
```

A simple coercer for mapping a Str of Int to Int If you can call Int on it, it'll be acceptable as an Int. This routine is package scoped and not exported when used.

### sub str-to-rat

```raku
sub str-to-rat(
    $val
) returns Result::Any
```

A simple coercer for mapping a Str of Rat to Rat If you can call Int on it, it'll be acceptable as an Int. This routine is package scoped and not exported when used.

### sub struct-int

```raku
sub struct-int(
    Str:D $name,
    Bool :$optional = Bool::False,
    :$default
) returns Mu
```

A factory for creating a struct element of type Int. By default this Type element will try and coerce Str values to Int.

### sub buf-to-str

```raku
sub buf-to-str(
    $val
) returns Result::Any
```

A simple coercer for mapping a Buf of Str to Str If you can call decode on it, it'll be acceptable as an Str. This routine is package scoped and not exported when used.

### sub struct-str

```raku
sub struct-str(
    Str:D $name,
    Bool :$optional = Bool::False,
    :$default
) returns Mu
```

A factory for creating a struct element of type Str No coercion behaviours are defined for this Type

### sub struct-rat

```raku
sub struct-rat(
    Str:D $name,
    Bool :$optional = Bool::False,
    :$default
) returns Mu
```

A factory for creating a struct element of type Rat. By default this Type element will try and coerce Str values to Rat.

### sub str-to-date

```raku
sub str-to-date(
    $val
) returns Result::Any
```

A simple coercer for mapping a Str containing a date string to a Date object This routine is package scoped and not exported when used.

### sub struct-date

```raku
sub struct-date(
    Str:D $name,
    Bool :$optional = Bool::False,
    :$default
) returns Mu
```

A factory for creating a struct element of type Date. Coerces date strings to Dat objects according to inbuild Date object behaviour.

### sub str-to-datetime

```raku
sub str-to-datetime(
    $val
) returns Result::Any
```

A simple coercer for mapping a Str containing an ISO time stamp string to a DateTime object This routine is package scoped and not exported when used.

### sub struct-datetime

```raku
sub struct-datetime(
    Str:D $name,
    Bool :$optional = Bool::False,
    :$default
) returns Mu
```

A factory for creating a struct element of type DateTime. Coerces date strings to Dat objects according to inbuild Date object behaviour.

### sub any-to-bool

```raku
sub any-to-bool(
    $val
) returns Result::Any
```

A Bool coercer, searching for truethy values. Since a simple coercer could just return a .so result, this function is a little more aggressive. .so logic is applied but strings are also checked for empty string and the string '0'.

### sub struct-bool

```raku
sub struct-bool(
    Str:D $name,
    Bool :$optional,
    Bool :$default
) returns Mu
```

A factory for creating a struct element of type Bool. A struct def for Bool types, this is built with the any-to-bool coercion function.

### sub struct-nested

```raku
sub struct-nested(
    Str:D $name,
    Structable::Struct $struct,
    :$optional = Bool::False,
    :$default,
    :&coercion,
    :&to-simple
) returns Mu
```

A factory for creating a struct element of another Structable::Struct. The provided struct will be used for simplifying and conforming the nested values. Conform and simplify actions cascade into the defenition.

### sub struct-list

```raku
sub struct-list(
    Str:D $name,
    Structable::Type $list-type,
    :$optional = Bool::False,
    :$default,
    :&coercion,
    :&to-simple
) returns Mu
```

A factory for creating a struct element list defenition. The List must be of a uniform type as specified by the Structable type provided. Conform and simplify actions cascade into the defenition.

### sub any-to-str

```raku
sub any-to-str(
    $val
) returns Result::Any
```

A basic simplifier which calls the .Str method to perform simplification This routine is package scoped and not exported when the module is used.

### sub simplify

```raku
sub simplify(
    Structable::Struct:D $s,
    Map:D $m
) returns Result::Any
```

Pack a given map according to a given struct. This function is the complement of conform and facilitates packing a map down to a simple map, ready for serialisation to a format such as JSON.

