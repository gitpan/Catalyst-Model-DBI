package Catalyst::Model::DBI;

use strict;
use base 'Catalyst::Model';
use MRO::Compat;
use mro 'c3';
use DBI;

our $VERSION = '0.29';

__PACKAGE__->mk_accessors( qw/_dbh _pid _tid/ );

=head1 NAME

Catalyst::Model::DBI - DBI Model Class

=head1 SYNOPSIS

  # use the helper to create a model for example
  perl script/myapp_create.pl model MyModel DBI dsn username password

  # lib/MyApp/Model/DBI.pm
  package MyApp::Model::DBI;

  use base 'Catalyst::Model::DBI';

  __PACKAGE__->config(
    dsn           => 'DBI:Pg:dbname=mydb;host=localhost',
    username      => 'pgsql',
    password      => '',
    options       => { AutoCommit => 1 },
  );

  1;

  # or load settings from a config file via Config::General for example
  # in your myapp.conf you could have

  name MyApp

  <Model::MyModel>
    dsn "DBI:Pg:dbname=mydb;host=localhost"
    username pgsql
    password ""
    <options>
      AutoCommit 1
    </options>
  </Model>

  # note that config settings always override Model settings

  # do something with $dbh inside a controller ...
  my $dbh = $c->model('MyModel')->dbh;

  # do something with $dbh inside a model ...
  my $dbh = $self->dbh;

=head1 DESCRIPTION

This is the C<DBI> model class.

=head1 METHODS

=over 4

=item new

Initializes DBI connection

=cut

sub new {
  my $self = shift->next::method( @_ );
  my ( $c, $config ) = @_;

  $self->{dsn} ||= $config->{dsn};
  $self->{username} ||= $config->{username} || $config->{user};
  $self->{password} ||= $config->{password} || $config->{pass};
  $self->{options} ||= $config->{options};

  $self->{namespace} ||= ref $self;
  $self->{additional_base_classes} ||= ();
  $self->{log} = $c->log;
  $self->{debug} = $c->debug;

  return $self;
}

=item $self->dbh

Returns the current database handle.

=cut

sub dbh {
  return shift->stay_connected;
}

=item $self->stay_connected

Returns a connected database handle.

=cut

sub stay_connected {
  my $self = shift;
  if ( $self->_dbh ) {
    if ( defined $self->_tid && $self->_tid != threads->tid ) {
      $self->_dbh( $self->connect );
    } elsif ( $self->_pid != $$ ) {
      $self->_dbh->{InactiveDestroy} = 1;
      $self->_dbh( $self->connect );
    } elsif ( ! $self->connected ) {
      $self->_dbh( $self->connect );
    }
  } else {
    $self->_dbh( $self->connect );
  }
  return $self->_dbh;
}

=item $self->connected

Returns true if the database handle is active and pingable.

=cut

sub connected {
  my $self = shift;
  return unless $self->_dbh;
  return $self->_dbh->{Active} && $self->_dbh->ping;
}

=item $self->connect

Connects to the database and returns the handle.

=cut

sub connect {
  my $self = shift;
  my $dbh;

  eval {
    $dbh = DBI->connect(
      $self->{dsn},
      $self->{username} || $self->{user},
      $self->{password} || $self->{pass},
      $self->{options}
    );
  };
  if ($@) {
    $self->{log}->debug( qq/Couldn't connect to the database "$@"/ )
      if $self->{debug};
  } else {
    $self->{log}->debug( 'Connected to the database via dsn:' . $self->{dsn} )
      if $self->{debug};
  }
  $self->_pid( $$ );
  $self->_tid( threads->tid ) if $INC{'threads.pm'};
  return $dbh;
}

=item $self->disconnect

Executes rollback if AutoCommit is active,
disconnects and unsets the database handle.

=cut

sub disconnect {
  my $self = shift;
  if( $self->connected ) {
    $self->_dbh->rollback unless $self->_dbh->{AutoCommit};
    $self->_dbh->disconnect;
    $self->_dbh( undef );
  }
}

sub DESTROY {
  my $self = shift;
  $self->disconnect if (defined $self->_dbh);
}

=back

=head1 SEE ALSO

L<Catalyst>, L<DBI>

=head1 AUTHOR

Alex Pavlovic, C<alex.pavlovic@taskforce-1.com>

=head1 COPYRIGHT

Copyright (c) 2005 - 2012
the Catalyst::Model::DBI L</AUTHOR>
as listed above.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
