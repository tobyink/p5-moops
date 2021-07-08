#!/usr/bin/env perl

=head1 SYNOPSIS

    deduper.pl --root_dir <root dir>

=head1 DESCRIPTION

This is a Moops version of Yanick's winning contribution to DFW.pm 2013 
contest, see L<https://github.com/yanick/dfw-contest.git>

See 
L<http://perlnews.org/2013/12/world-wide-perl-competition>
L<http://dfw.pm.org/winners.html>

to demonstrate Moops...

=cut

use Moops;
use Carp 'verbose';

class Deduper {
	use Moo;    #for _options_config
	use Path::Iterator::Rule;
	use List::MoreUtils qw/ uniq /;
	use MooX::Options;

	option root_dir => (
		is            => 'ro',
		format        => 's',
		documentation => 'path to dedupe',
		required      => 1,
	);

	option hash_size => (
		isa     => Int,
		is      => 'ro',
		format  => 'i',
		default => '1024',
		trigger => method {
			Deduper::File->hash_size( $self->hash_size );
		},
		documentation => 'size of the file hash',
	);

	option stats => (
		isa           => Bool,
		is            => 'ro',
		documentation => 'report statistics',
	);

	option max_files => (
		traits    => ['Counter'],       #doesn't work in Moops?
		isa       => Int,
		format    => 'i',
		is        => 'ro',
		predicate => 'has_max_files',
		default   => 0,
		documentation => 'max number of files to scan (for testing)',
		handles       => {
			dec_files_to_scan => 'dec',
		},
	);

	has start_time => (
		is      => 'ro',
		isa     => Int,
		default => sub { 0 + time },
	);

	has file_iterator => (
		is      => 'ro',
		lazy    => 1,
		default => sub {
			my $self = shift;
			return Path::Iterator::Rule->new->file->iter_fast(
				$self->root_dir,
				{
					follow_symlinks => 0,
					sorted          => 0,
				}
			);
		},
	);

	has finished => (
		is      => 'rw',
		default => 0,
	);

	has files => (
		is      => 'ro',
		default => sub { {} },
	);

	method all_files {

		my @files;
		for my $v ( values %{ $self->files } ) {
			push @files,
			  ref $v eq 'Deduper::File' ? $v : map { @$_ } values %$v;
		}

		return @files;
	}

	method BUILD {

		die "root dir does not exist" if ( !-d $self->root_dir );

		if ( $self->max_files ) {
			after next_file {
				$self->dec_files_to_scan;
				$self->finished(1) unless $self->max_files > 0;
			}
		}

		if ( $self->stats ) {
			after run { $self->print_stats };
		}
	}

	method add_file($file) {
		if ( my $ref = $self->files->{ $file->size } ) {
			if ( ref $ref eq 'Deduper::File' ) {
				$ref = $self->files->{ $file->size } =
				  { $ref->hash => [$ref] };
			}
			push @{ $ref->{ $file->hash } }, $file;
		}
		else {
			# nothing yet, just push the sucker in
			$self->files->{ $file->size } = $file;
		}

	};

	method find_orig($file) {

		# do we have any file of the same size?
		my $candidates = $self->files->{ $file->size }
		  or return;

		  my @c;

		  if ( ref $candidates eq 'Deduper::File' ) {
			return if $candidates->hash ne $file->hash;
			@c = ($candidates);
		}
		else {
			@c = @{ $candidates->{ $file->hash } || return };
		}

		# first check if any share the same inode
		my $inode = $file->inode;
		  for (@c) {
			return $_ if $_->inode == $inode;
		}

		# then check if dupes
		for (@c) {
			return $_ if $_->is_dupe($file);
		}

		return;
	};

	method is_dupe($file) {
		return $_
		  for $self->find_orig($file);

		  $self->add_file($file);

		  return;
	};

	method next_file {
		return if $self->finished;

		while ( my $file = $self->file_iterator->() ) {
			return Deduper::File->new( path => $file );
		}

		$self->finished(1);
		return;
	}

	method next_dupe {
		return if $self->finished;

		while ( my $file = $self->file_iterator->() ) {
			$file = Deduper::File->new( path => $file );
			my $orig = $self->is_dupe($file) or next;
			return $orig => $file;
		}

		$self->finished(1);
		return;
	}

	method print_dupes($separator) {
		$separator ||= "\t";

		  while ( my @x = $self->next_dupe ) {
			say join $separator, @x;
		}
	};

	method all_dupes {
		my %dupes;
		while ( my ( $orig, $dupe ) = $self->next_dupe ) {
			push @{ $dupes{ $orig->path } }, $orig, $dupe;
		}

		# we want them all nice and sorted
		my @dupes;
		while ( my ( $orig, $dupes ) = each %dupes ) {
			my %seen_inode;
			push @dupes,
			  [ grep { not $seen_inode{ $_->inode }++ }
				  uniq sort { $a->path cmp $b->path } @$dupes ];
		}

		# filter out the dupes that are just hard links
		@dupes = grep { @$_ > 1 } @dupes;

		return sort { $a->[0]->path cmp $b->[0]->path } @dupes;
	}

	method run {
		say join "\t", map { $_->path } @$_ for $self->all_dupes;
	}

	method print_stats {
		say '-' x 30;
		say "time taken: ", time - $self->start_time, " seconds";

		my ($nbr_files, $nbr_hash, $nbr_end_hash, $nbr_md5);

		for my $f ( $self->all_files ) {
			$nbr_files++;
			$nbr_hash++     if $f->has_hash;
			$nbr_end_hash++ if $f->has_end_hash;
			$nbr_md5++      if $f->has_md5;
		}

		say join " / ", $nbr_files, $nbr_hash, $nbr_end_hash, $nbr_md5;
	}

}

class Deduper::File {
	use Digest::xxHash;

	has hash_size => (
		isa     => Int,
		is      => 'rw',
		default => 1024,
	);

	has path => (
		is       => 'ro',
		required => 1,
	);

	has inode => (
		is        => 'ro',
		lazy      => 1,
		predicate => 'has_inode',
		default => method { return ( ( stat $self->path )[1] ) },
	);

	has size => (
		is      => 'ro',
		lazy    => 1,
		default => method {
			return -s $self->path;
		},
	);

	has digest => (
		is        => 'ro',
		lazy      => 1,
		predicate => 'has_md5',
		default   => method {
			sysopen my $fh, $self->path, 0;
			my $digest = Digest::xxHash->new(613);
			my $chunk;
			while ( sysread $fh, $chunk, 1024 * 1024 ) {
				$digest->add($chunk);
			}
			return $digest->digest;
		},
	);

	# the "hash" is simply a 1024 bit segment in the middle
	# of the file. Hopefully the middle part will deal with
	# similar headers and footers
	has hash => (
		is        => 'ro',
		lazy      => 1,
		predicate => 'has_hash',
		default   => method {
			sysopen my $fh, $self->path, 0;
			sysread $fh, my $hash, $self->hash_size;
			return $hash;
		},
	);

	has end_hash => (
		is        => 'ro',
		lazy      => 1,
		predicate => 'has_end_hash',
		default   => method {
			sysopen my $fh, $self->path, 0;
			sysseek $fh, -$self->hash_size, 2;
			sysread $fh, my $hash, $self->hash_size;
			return $hash;
		},
	);

	method is_dupe($other) {

		# if we are here, it's assumed the sizes are the same
		# and the beginning hashes are the same

		# different hashes?
		return $self->end_hash eq $other->end_hash
		  && $self->digest eq $other->digest;
	};
}

class main {
	Deduper->new_with_options->run;    # modulino time!
}
