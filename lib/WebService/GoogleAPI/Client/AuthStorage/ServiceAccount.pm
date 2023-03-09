use strictures;

package WebService::GoogleAPI::Client::AuthStorage::ServiceAccount;

# VERSION

# ABSTRACT: Manage access tokens from a service account file

=head1 SYNOPSIS

This class provides an auth backend for service account files downloaded from
your google cloud console. For user accounts, please see
L<WebService::GoogleAPI::AuthStorage::GapiJSON>.

This backend is only for explicitly passing a service account JSON file. It will
not attempt to find one by itself, or to do the Application Default Credentials,
at least yet.

This backend will cache tokens in memory for any set of scopes requested, and
for any user you ask to impersonate (more on that later).

This class mixes in L<WebService::GoogleAPI::Client::AuthStorage>, and provides
all attributes and methods from that role. As noted there, the C<ua> is usually managed by 
the L<WebService::GoogleAPI::Client> object this is set on.

=cut

use Moo;
use Carp;
use Mojo::JWT::Google;

=attr scopes

A read/write attribute containing the scopes the service account is asking access to.
Will coerce a space seperated list of scopes into the required arrayref of scopes.

=cut

has scopes => is => 'rw',
    coerce => sub {
      my $arg = shift;
      return [ split / /, $arg ] unless ref $arg eq 'ARRAY';
      return $arg;
    },
    default => sub { [] };

=attr user

The user you want to impersonate. Defaults to the empty string, which signifies
no user. In order to impersonate a user, you need to have domain-wide delegation
set up for the service account.

=cut

has user    => is => 'rw',
    coerce  => sub { $_[0] || '' },
    default => '';

with 'WebService::GoogleAPI::Client::AuthStorage';

=attr path

The location of the file containing the service account credentials. This is
downloaded from your google cloud console's service account page.

=cut

has path     => is => 'rw',
    required => 1,
    trigger  => 1;

sub _trigger_path {
  my ($self) = @_;
  $self->jwt(Mojo::JWT::Google->new(from_json => $self->path));
}


=attr jwt

An instance of Mojo::JWT::Google used for retrieving the access tokens. This is
built whenever the C<path> attribute is set.

=cut

has jwt => is => 'rw';

=attr tokens

A hash for caching the tokens that have been retrieved by this object. It caches on 
scopes (via the C<scopes_string> method) and then user.

=cut

has tokens  => is => 'ro',
    default => sub { {} };

=method get_access_token

Return an access token for the current user (if any) and scopes from the cache if exists,
otherwise retrieve a new token with C<refresh_access_token>.

=cut

sub get_access_token {
  my ($self) = @_;
  my $token = $self->tokens->{ $self->scopes_string }{ $self->user };
  return $self->refresh_access_token unless $token;
  return $token;
}

=method refresh_access_token

Retrieve an access token for the current user (if any) and scopes from Google's auth API,
using a JWT.

=cut

sub refresh_access_token {
  my ($self) = @_;
  croak "Can't get a token without a set of scopes" unless @{ $self->scopes };

  $self->jwt->scopes($self->scopes);
  if ($self->user) {
    $self->jwt->user_as($self->user);
  } else {
    $self->jwt->user_as(undef);
  }

  my $new_token = $self->refresh_service_account_token($self->jwt);

  $self->tokens->{ $self->scopes_string }{ $self->user } = $new_token;
  return $new_token;
}

=method scopes_string

Return the list of scopes as a space seperated string.

=cut

sub scopes_string {
  my ($self) = @_;
  return join ' ', @{ $self->scopes };
}


9001
