package Catalyst::Model::DBI;

use strict;
use base 'Catalyst::Base';
use NEXT;
use DBI;

our $VERSION = '0.10';

__PACKAGE__->mk_accessors('dbh');

=head1 NAME

Catalyst::Model::DBI - DBI Model Class

=head1 SYNOPSIS

	# use the helper
	create model DBI DBI dsn user password
	
	# lib/MyApp/Model/DBI.pm
	package MyApp::Model::DBI;
	
	use base 'Catalyst::Model::DBI';
	
	__PACKAGE__->config(
		dsn           => 'dbi:Pg:dbname=myapp',
		password      => '',
		user          => 'postgres',
		options       => { AutoCommit => 1 },
	);
	
	1;
	
	my $dbh = $c->model('DBI')->dbh;
	#do something with $dbh ...
	
=head1 DESCRIPTION

This is the C<DBI> model class.

=head1 METHODS

=over 4

=item new

Initializes DBI connection

=cut

sub new {
    my ( $self, $c ) = @_;
    $self = $self->NEXT::new($c);
    $self->{namespace}               ||= ref $self;
    $self->{additional_base_classes} ||= ();
	eval { 
		$self->dbh( 
			DBI->connect( 
				$self->{dsn}, 
				$self->{user}, 
				$self->{password},
				$self->{options}
			)
		);
	};
    if ($@) { $c->log->debug( qq{Couldn't connect to the database "$@"} ) if $c->debug }
    else { $c->log->debug ( q{Connected to the database} ) if $c->debug; }
    return $self;
}

=item $self->dbh

Returns the current database handle.

=back

=head1 SEE ALSO

L<Catalyst>, L<DBI>

=head1 AUTHOR

Alex Pavlovic, C<alex.pavlovic@taskforce-1.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
