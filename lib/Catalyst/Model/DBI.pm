package Catalyst::Model::DBI;

use strict;
use base 'Catalyst::Model';
use NEXT;
use DBI;

our $VERSION = '0.14';

__PACKAGE__->mk_accessors( qw/_dbh _pid _tid/ );

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
	$self->{log} = $c->log;
	$self->{debug} = $c->debug;
	return $self;
}

sub dbh {
	return shift->stay_connected;
}

sub stay_connected {
	my $self = shift;
	if ( $self->_dbh ) {
		if ( defined $self->_tid && $self->_tid != threads->tid ) {
			$self->_dbh ( $self->connect );
      		} elsif ( $self->_pid != $$ ) {
			$self->_dbh->{InactiveDestroy} = 1;
			$self->_dbh ( $self->connect );
		} elsif ( ! $self->connected ) {
			$self->_dbh ( $self->connect );
		}
	} else {
		$self->_dbh ( $self->connect );
	}
	return $self->_dbh;
}

sub connected {
	my $self = shift;
	return $self->_dbh->{Active} && $self->_dbh->ping;
}

sub connect {
	my $self = shift;
	my $dbh;
	eval { 
		$dbh = DBI->connect( 
			$self->{dsn}, 
			$self->{user}, 
			$self->{password},
			$self->{options}
		);
	};
	if ($@) { $self->{log}->debug( qq{Couldn't connect to the database "$@"} ) if $self->{debug} }
	else { $self->{log}->debug ( 'Connected to the database via dsn:' . $self->{dsn} ) if $self->{debug}; }
	$self->_pid ( $$ );
	$self->_tid ( threads->tid ) if $INC{'threads.pm'};
	return $dbh;
}

sub disconnect {
	my $self = shift;
	if( $self->connected ) {
		$self->_dbh->rollback unless $self->_dbh->{AutoCommit};
		$self->_dbh->disconnect;
		$self->_dbh(undef);
	}
}

sub DESTROY { 
	shift->disconnect;
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
