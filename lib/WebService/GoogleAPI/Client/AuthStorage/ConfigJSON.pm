use strictures;

package WebService::GoogleAPI::Client::AuthStorage::ConfigJSON;

# ABSTRACT: Specific methods to fetch tokens from JSON data sources

use Moo;
use Config::JSON;
use Carp;

with 'WebService::GoogleAPI::Client::AuthStorage';

has 'path' => ( is => 'rw', default => './gapi.json' );    # default is gapi.json

has 'tokensfile' => ( is => 'rw' );  # Config::JSON object pointer

# NOTE- this type of class has getters and setters b/c the implementation of
# getting and setting depends on what's storing

sub BUILD {
  my ($self) = @_;
  $self->tokensfile(Config::JSON->new($self->path));
  return $self;
}

sub refresh_access_token {
  ... #TODO
}

sub get_credentials_for_refresh {
  my ($self, $user) = @_;
  return {
    map { ( $_ => $self->get_from_storage($_) ) }
      qw/client_id client_secret refresh_token/
  };
}

sub get_token_emails_from_storage {
  my ($self) = @_;
  my $tokens = $self->get_from_storage('tokens');
  return [keys %$tokens];
}

sub get_from_storage {
  my ($self, $key) = @_;
  if ($key =~ /_token/) {
    return $self->tokensfile->get("gapi/tokens/${\$self->user}/$key")
  } else {
    return $self->tokensfile->get("gapi/$key")
  }
}

sub get_access_token {
  my ($self) = @_;
  my $value = $self->get_from_storage('access_token');
  return $value
}

sub get_scopes_from_storage_as_array {
  carp 'get_scopes_from_storage_as_array is being deprecated, please use the more succint scopes accessor';
  return $_[0]->scopes
}

# NOTE - the scopes are stored as a space seperated list, and this method
# returns an arrayref
sub scopes {
  my ($self) = @_;
  return [split / /, $self->tokensfile->get('gapi/scopes')];
}
1;
