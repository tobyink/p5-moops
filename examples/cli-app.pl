#!/usr/bin/env perl

use Moops;
use Carp 'verbose';

class UsrBinCat
{
	use MooX::Options;
	
	option filename => (
		is       => 'ro',
		format   => 's',
		required => 1,
		doc      => 'the file to display'
	);
	
	method BUILD
	{
		open my $fh, "<", $self->filename
			or die  "cannot open ${\ $self->filename }: $!";
		
		print while <$fh>;
	}
}

UsrBinCat->new_with_options;
