use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package Moops::TraitFor::Keyword::mutable;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.033';

use Moo::Role;

around should_make_immutable => sub { 0 };

1;
