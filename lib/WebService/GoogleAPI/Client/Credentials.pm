use strictures;

package WebService::GoogleAPI::Client::Credentials;

# ABSTRACT: Credentials for particular Client instance. You can use this module
# as singleton also if you need to share credentials between two or more
# instances


use Carp;
use Moo;
use WebService::GoogleAPI::Client::AuthStorage::ConfigJSON;
with 'MooX::Singleton';


has 'access_token' => ( is => 'rw' );
has 'user'         => ( is => 'rw', trigger => \&get_access_token_for_user );
has 'auth_storage' => 
  is => 'rw',
  default => sub { WebService::GoogleAPI::Client::AuthStorage::ConfigJSON->new },
  lazy => 1;

=method get_access_token_for_user

Automatically get access_token for current user if auth_storage is set

=cut

sub get_access_token_for_user {
  my ($self) = @_;
  $self->access_token($self->auth_storage->get_access_token_from_storage($self->user));
  return $self;
}

sub get_scopes_as_array {
  my ( $self ) = @_;
  $self->auth_storage->get_scopes_from_storage_as_array;
}

1;
