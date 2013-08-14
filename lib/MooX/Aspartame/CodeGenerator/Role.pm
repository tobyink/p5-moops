use v5.14;
use strict;
use warnings FATAL => 'all';
no warnings qw(void once uninitialized numeric);

package MooX::Aspartame::CodeGenerator::Role;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use Moo;
extends qw( MooX::Aspartame::CodeGenerator );

1;
