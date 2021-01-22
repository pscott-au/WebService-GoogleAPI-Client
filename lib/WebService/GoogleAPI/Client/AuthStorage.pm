use strictures;

package WebService::GoogleAPI::Client::AuthStorage;

# ABSTRACT: JSON File Persistence for Google OAUTH Project and User Access Tokens

## is client->auth_storage
## or is Client->ua->auth_storage delegated as auth_storage to client

## or is UserAgent->credentials

use Moo::Role;
with 'MooX::Singleton';

use WebService::GoogleAPI::Client::AuthStorage::AccessToken;

requires qw/
  refresh_access_token
  get_access_token
  scopes
/;

around get_access_token => sub {
  my ($orig, $self) = @_;
  my $user = $self->user;
  my $token = $self->$orig;
  my $wrapped = WebService::GoogleAPI::Client::AuthStorage::AccessToken->new(
    user => $user, token => $token );
  $self->access_token($wrapped);
  return $wrapped;
};

has access_token =>
  is => 'rw';

has user         =>
  is => 'rw',
  trigger => sub { shift->get_access_token };


1;
