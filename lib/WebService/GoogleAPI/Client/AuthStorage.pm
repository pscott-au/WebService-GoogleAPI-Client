use strictures;
package WebService::GoogleAPI::Client::AuthStorage;

# ABSTRACT: JSON File Persistence for Google OAUTH Project and User Access Tokens

use Moo::Role;
use Carp;
use WebService::GoogleAPI::Client::AccessToken;

# some backends may have scopes as read only, and others as read write
requires qw/
  scopes
  refresh_access_token
  get_access_token
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

has user => is => 'rw';

# this is managed by the BUILD in ::Client::UserAgent,
# and by the BUILD in ::Client
has ua => is => 'rw', weak_ref => 1;

1;
