use strictures;

package WebService::GoogleAPI::Client::AuthStorage::ConfigJSON;

# ABSTRACT: Specific methods to fetch tokens from JSON data sources

use Moo;
use Config::JSON;
use Carp;

has 'path' => ( is => 'rw', default => 'gapi.json' );    # default is gapi.json

# has 'tokensfile';  # Config::JSON object pointer
my $tokensfile;
has 'debug' => ( is => 'rw', default => 0 );

## cringe .. getters and setters, tokenfile?, global $tokensfile? .. *sigh*

sub setup
{
  my ( $self ) = @_;
  $tokensfile = Config::JSON->new( $self->path );
  return $self;
}

sub get_credentials_for_refresh
{
  my ( $self, $user ) = @_;
  return {
    client_id     => $self->get_client_id_from_storage(),
    client_secret => $self->get_client_secret_from_storage(),
    refresh_token => $self->get_refresh_token_from_storage( $user )
  };
}

sub get_token_emails_from_storage
{
  my $tokens = $tokensfile->get( 'gapi/tokens' );
  return [keys %$tokens];
}


sub get_client_id_from_storage
{
  return $tokensfile->get( 'gapi/client_id' );
}

sub get_client_secret_from_storage
{
  return $tokensfile->get( 'gapi/client_secret' );
}

sub get_refresh_token_from_storage
{
  my ( $self, $user ) = @_;
  carp "get_refresh_token_from_storage(" . $user . ")" if $self->debug;
  return $tokensfile->get( 'gapi/tokens/' . $user . '/refresh_token' );
}

sub get_access_token_from_storage
{
  my ( $self, $user ) = @_;
  return $tokensfile->get( 'gapi/tokens/' . $user . '/access_token' );
}

sub set_access_token_to_storage
{
  my ( $self, $user, $token ) = @_;
  return $tokensfile->set( 'gapi/tokens/' . $user . '/access_token', $token );
}

sub get_scopes_from_storage
{
  my ( $self ) = @_;
  return $tokensfile->get( 'gapi/scopes' );    ## NB - returns an array - is stored as space sep list
}

sub get_scopes_from_storage_as_array
{
  my ( $self ) = @_;
  return [split( ' ', $tokensfile->get( 'gapi/scopes' ) )];    ## NB - returns an array - is stored as space sep list
}

1;
