use strictures;

package WebService::GoogleAPI::Client::AuthStorage::GapiJSON;

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
  my $missing = grep !$_, map $self->get_from_storage($_), qw/client_id client_secret/;
  croak <<NOCLIENT if $missing;
Malformed gapi.json detected. We need the client_id and client_secret in order
to refresh expired tokens
NOCLIENT

  return $self;
}

sub refresh_access_token {
  my ($self) = @_;
  my %p = map { ( $_ => $self->get_from_storage($_) ) }
     qw/client_id client_secret refresh_token/;

  croak <<MISSINGCREDS unless $p{refresh_token};
If your credentials are missing the refresh_token - consider removing the auth at
https://myaccount.google.com/permissions as The oauth2 server will only ever mint one refresh
token at a time, and if you request another access token via the flow it will operate as if
you only asked for an access token.
MISSINGCREDS
  $p{grant_type} = 'refresh_token';
  my $user = $self->user;

  my $tx = $self->ua->post('https://www.googleapis.com/oauth2/v4/token' => form => \%p);
  my $new_token = $tx->res->json('/access_token');
  unless ($new_token) {
    croak "Failed to refresh access token: ",
      join ' - ', map $tx->res->json("/$_"), qw/error error_description/
      if $tx->res->json;
    # if the error doesn't come from google
    croak "Unknown error refreshing access token";
  }

  $self->tokensfile->set("gapi/tokens/$user/access_token", $new_token);
  return $new_token;
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
