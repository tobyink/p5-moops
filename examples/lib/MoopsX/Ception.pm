package MoopsX::Ception;

use Moo;
extends 'Moops';

sub class_for_parser {
	require MoopsX::Ception::Parser;
	'MoopsX::Ception::Parser';
}

1;
