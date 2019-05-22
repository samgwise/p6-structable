[![Build Status](https://travis-ci.org/samgwise/p6-structable.svg?branch=master)](https://travis-ci.org/samgwise/p6-structable)

NAME Structable - Runtime validation of associative datastructures
==================================================================

SYNOPSIS
========

    use Structable;

    my $struct = struct-def
        (struct-int    'id_weight'),
        (struct-str    'name_subject'),
        (struct-rat    'weight_subject'),
        (struct-date   'date_measure');

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
        , weight_subject    => "7.65",
        , date_measure      => '2019-01-25',
        }
    ).ok("").perl;
    # { :id_weight(3), …
    # The conformed values have been coerced into their specified types!

DESCRIPTION
===========

The Structable module provides a mechanism for defining an ordered and typed data defenition.

Validating input like JSON is often a tedious task, howevver with Structable you can create concise definitions which you can apply at runtime. If the input is valid (perhaps with a bit of coercion) then the conformed data will be returned in a Result::OK object and if there was something wrong a Result::Err will be returned with a helpful error message. This means that you can use conform operations in a stream of values instead of resorting to try/catch constructs to handle your validation errors.

The struct defenition also defines an order, so by grabing a list of keys you can easily iterate over values in a conformed Map in the order you specified.

Custom types
------------

If you need more types than those bundled in this module you can add your own! All members of a Strucatable::Struct are Structable::Type[T], a parametric role. Simply pass your type as the role's type parameter and away you go.

Caveats
-------

Although this module helps provide assurances about the data you are injesting it has not yet been audited and tested to provide any assurances regarding security. Data from an unstrusted source may still be untrustworthy after passing through a conform step provided by this module. Particular caution should be given to the size of payload you are conforming there are no inbuilt mechanisims to prevent this style of abuse in this module.

AUTHOR
======

Sam Gillespie <samgwise@gmail.com>

COPYRIGHT AND LICENCE
=====================

Copyright 2018 Sam Gillespie

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

### sub struct-def

```perl6
sub struct-def(
    +
) returns Mu
```

A factory for defining a new C<Struct> defenition. Each argument must be a C<Structable::Type> and is checked on execution of this function.

### sub conform

```perl6
sub conform(
    Structable::Struct $s,
    Map $m
) returns Result
```

This subroutine attempts to conform a Map (such as a Hash) to a given struct. The outcome is returned as a C<Result> object. A C<Result::OK> holds a filtered version of a hash which adhears to the given struct. A C<Result::Err> represents an error and holds an error message describing why the given Map is not conformant to the given Struct.

### sub str-to-int

```perl6
sub str-to-int(
    $val
) returns Result
```

A simple coercer for mapping a Str of Int to Int If you can call Int on it, it'll be acceptable as an Int. This routine is package scoped and not exported when used.

### sub str-to-rat

```perl6
sub str-to-rat(
    $val
) returns Result
```

A simple coercer for mapping a Str of Rat to Rat If you can call Int on it, it'll be acceptable as an Int. This routine is package scoped and not exported when used.

### sub struct-int

```perl6
sub struct-int(
    Str:D $name,
    Bool :$optional = Bool::False
) returns Mu
```

A factory for creating a struct element of type Int. By default this Type element will try and coerce Str values to Int.

### sub struct-str

```perl6
sub struct-str(
    Str:D $name,
    Bool :$optional = Bool::False
) returns Mu
```

A factory for creating a struct element of type Str No coercion behaviours are defined for this Type

### sub struct-rat

```perl6
sub struct-rat(
    Str:D $name,
    Bool :$optional = Bool::False
) returns Mu
```

A factory for creating a struct element of type Rat. By default this Type element will try and coerce Str values to Rat.

### sub str-to-date

```perl6
sub str-to-date(
    $val
) returns Result
```

A simple coercer for mapping a Str containing a date string to a Date object TODO: conform-to-map to reverse this transofrmation. This routine is package scoped and not exported when used.

### sub struct-date

```perl6
sub struct-date(
    Str:D $name,
    Bool :$optional = Bool::False
) returns Mu
```

A factory for creating a struct element of type Date. Coerces date strings to Dat objects according to inbuild Date object behaviour.

### sub str-to-datetime

```perl6
sub str-to-datetime(
    $val
) returns Result
```

A simple coercer for mapping a Str containing an ISO time stamp string to a DateTime object TODO: conform-to-map to reverse this transofrmation. This routine is package scoped and not exported when used.

### sub struct-datetime

```perl6
sub struct-datetime(
    Str:D $name,
    Bool :$optional = Bool::False
) returns Mu
```

A factory for creating a struct element of type DateTime. Coerces date strings to Dat objects according to inbuild Date object behaviour.

