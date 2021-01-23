use strictures;
package WebService::GoogleAPI::Client::AuthStorage::ServiceAccount;

# ABSTRACT: Specific methods to fetch tokens from a service
# account json file

use Moo;
use Carp;
use Mojo::JWT::Google;

has scopes =>
  is => 'rw',
  coerce => sub {
    my $arg = shift;
    return [ split / /, $arg ] unless ref $arg eq 'ARRAY';
    return $arg
  },
  default => sub { [] };

has user =>
  is => 'rw', 
  coerce => sub { $_[0] || '' },
  deafault => '';

with 'WebService::GoogleAPI::Client::AuthStorage';

has path =>
  is => 'rw',
  required => 1,
  trigger => 1;

has jwt =>
  is => 'rw';

# we keep record of the tokens we've gotten so far
has tokens =>
  is => 'ro',
  default => sub { {} };


sub _trigger_path {
  my ($self) = @_;
  $self->jwt(
    Mojo::JWT::Google->new(from_json => $self->path)
  );
}

sub scopes_string {
  my ($self) = @_;
  return join ' ', @{$self->scopes}
}

sub get_access_token {
  my ($self) = @_;
  use Data::Printer; p $self;
  my $token = $self->tokens->{$self->scopes_string}{$self->user};
  return $self->refresh_access_token unless $token;
  return $token
}

sub refresh_access_token {
  my ($self) = @_;
  croak "Can't get a token without a set of scopes" unless @{$self->scopes};

  $self->jwt->scopes($self->scopes);
  if ($self->user) {
    $self->jwt->user_as($self->user)
  } else {
    $self->jwt->user_as(undef)
  }

  my $tx = $self->ua->post('https://www.googleapis.com/oauth2/v4/token' => form => $self->jwt->as_form_data);
  my $new_token = $tx->res->json('/access_token');
  croak('refresh_access_token failed') unless $new_token;

  $self->tokens->{$self->scopes_string}{$self->user} = $new_token;
  return $new_token
}

9001
