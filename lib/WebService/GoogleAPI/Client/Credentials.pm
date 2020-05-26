use strictures;

package WebService::GoogleAPI::Client::Credentials;

# ABSTRACT: Credentials for particular Client instance. You can use this module as singleton also if you need to share
#           credentials between two or more modules


use Carp;
use Moo;
with 'MooX::Singleton';


has 'access_token' => ( is => 'rw' );
#TODO- user is a little bit imprecise, b/c a service account
#doesn't necessarily have a user
has 'user'         => ( is => 'rw', trigger => \&get_access_token_for_user );                                # full gmail, like peter@shotgundriver.com
has 'auth_storage' => ( is => 'rw', default => sub { WebService::GoogleAPI::Client::AuthStorage->new } );    # dont delete to able to configure

=method get_access_token_for_user

Automatically get access_token for current user if auth_storage is set

=cut

sub get_access_token_for_user {
  my ($self) = @_;
  if ($self->auth_storage->is_set) {
    # check that auth_storage initialized fine
    $self->access_token(
      $self->auth_storage->get_access_token_from_storage($self->user));
  } else {
    croak q/Can't get access token, Storage isn't set/;
  }
  return $self;
}

sub get_scopes_as_array {
  my ( $self ) = @_;
  if ($self->auth_storage->is_set) {
    return $self->access_token( $self->auth_storage->get_scopes_from_storage_as_array() );
  }
  else
  {
    croak q/Can't get access token for specified user because storage isn't set/;
  }

}

1;
