use strictures;

package WebService::GoogleAPI::Client::AuthStorage;

# ABSTRACT: JSON File Persistence for Google OAUTH Project and User Access Tokens

## is client->auth_storage
## or is Client->ua->auth_storage delegated as auth_storage to client

## or is UserAgent->credentials

use Moo::Role;
use Carp;

requires qw/
  refresh_token
  get_access_token_from_storage
  set_access_token_to_storage
  scopes
/;

=method setup

Set appropriate storage

  my $auth_storage = WebService::GoogleAPI::Client::AuthStorage->new;
  $auth_storage->setup; # by default will be config.json
  $auth_storage->setup({type => 'jsonfile', path => '/abs_path' });


=cut

sub setup {
  my ($self, $params) = @_;
  if ($params->{type} eq 'jsonfile') {
    $self->storage->path($params->{path});
    $self->storage->setup;
    $self->is_set(1);
  } elsif ($params->{type} eq 'servicefile') {
    $self->storage(
      WebService::GoogleAPI::Client::AuthStorage::ServiceAccount->new(path => $path);
    );
    $self->is_set(1);
  } else {
    croak "Unknown storage type.";
  }
  return $self;
}

### Below are list of methods that each Storage subclass must provide

=method get_credentials_for_refresh

Return all parameters that is needed for Mojo::Google::AutoTokenRefresh::refresh_access_token() function: client_id, client_secret and refresh_token

$c->get_credentials_for_refresh('examplemail@gmail.com')

This method must have all subclasses of WebService::GoogleAPI::Client::AuthStorage

=cut


1;
