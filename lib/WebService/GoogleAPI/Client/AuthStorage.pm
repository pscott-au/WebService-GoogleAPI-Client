use strictures;

package WebService::GoogleAPI::Client::AuthStorage;

# ABSTRACT: JSON File Persistence for Google OAUTH Project and User Access Tokens

## is client->auth_storage
## or is Client->ua->auth_storage delegated as auth_storage to client

## or is UserAgent->credentials

use Moo::Role;
use Carp;
with 'MooX::Singleton';

use WebService::GoogleAPI::Client::AccessToken;

requires qw/
  refresh_access_token
  get_access_token
  scopes
/;

around get_access_token => sub {
  my ($orig, $self) = @_;
  my $user = $self->user;
  my $scopes = $self->scopes;

  my $token = $self->$orig;
  my $class = 'WebService::GoogleAPI::Client::AccessToken';
  return $token if ref $token eq $class;
  return WebService::GoogleAPI::Client::AccessToken->new(
    user => $user, token => $token, scopes => $scopes );
};

has access_token =>
  is => 'rw',
  isa => sub {
    my $class = 'WebService::GoogleAPI::Client::AccessToken';
    croak "access_token must be an instance of $class" unless ref $_[0] eq $class
  };

has user         =>
  is => 'rw',
  trigger => sub { shift->get_access_token };


1;
