use strictures;

package WebService::GoogleAPI::Client::AuthStorage::ConfigJSON;

# ABSTRACT: Specific methods to fetch tokens from JSON data sources

use Moo;
use Config::JSON;
use Carp;

with 'WebService::GoogleAPI::Client::AuthStorage';

has 'path' => ( is => 'rw', default => 'gapi.json' );    # default is gapi.json

has 'tokensfile' => ( is => 'rw' );  # Config::JSON object pointer
has 'debug' => ( is => 'rw', default => 0 );

# NOTE- this type of class has getters and setters b/c the implementation of
# getting and setting depends on what's storing

sub BUILD {
  my ($self) = @_;
  $self->tokensfile(Config::JSON->new($self->path));
  return $self;
}

sub get_credentials_for_refresh {
  my ($self, $user) = @_;
  return {
    client_id     => $self->get_client_id_from_storage(),
    client_secret => $self->get_client_secret_from_storage(),
    refresh_token => $self->get_refresh_token_from_storage($user)
  };
}

sub get_token_emails_from_storage {
  my ($self) = @_;
  my $tokens = $self->tokensfile->get('gapi/tokens');
  return [keys %$tokens];
}


sub get_client_id_from_storage {
  my ($self) = @_;
  return $self->tokensfile->get('gapi/client_id');
}

sub get_client_secret_from_storage {
  my ($self) = @_;
  return $self->tokensfile->get('gapi/client_secret');
}

sub get_refresh_token_from_storage {
  my ($self, $user) = @_;
  carp "get_refresh_token_from_storage(" . $user . ")" if $self->debug;
  return $self->tokensfile->get('gapi/tokens/' . $user . '/refresh_token');
}

sub get_access_token_from_storage {
  my ($self, $user) = @_;
  return $self->tokensfile->get('gapi/tokens/' . $user . '/access_token');
}

sub set_access_token_to_storage {
  my ($self, $user, $token) = @_;
  return $self->tokensfile->set('gapi/tokens/' . $user . '/access_token',
    $token);
}

sub get_scopes_from_storage {
  my ($self) = @_;
  return $self->tokensfile->get('gapi/scopes');
}

sub get_scopes_from_storage_as_array {
  carp 'get_scopes_from_storage_as_array is being deprecated, please use the more succint scopes accessor';
  return $_[0]->scopes
}

# NOTE - the scopes are stored as a space seperated list
sub scopes {
  my ($self) = @_;
  return [split / /, $self->tokensfile->get('gapi/scopes')];
}
1;
