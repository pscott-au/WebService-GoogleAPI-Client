package WebService::GoogleAPI::Client::AccessToken;

# ABSTRACT - A small class for bundling user and scopes with a token
use Moo;

use overload '""' => sub { shift->token };

has [ qw/token user scopes/ ] =>
  is => 'ro',
  required => 1;

=head1 SYNOPSIS

  my $token = $gapi->get_access_token # returns this class
  # {
  #   token   => '...',
  #   user    => 'the-user-that-it's-for',
  #   scopes  => [ 'the', 'scopes', 'that', 'its', 'for' ]
  # }

This is a simple class which contains the data related to a Google Cloud access token
that bundles the related user and scopes.

It overloads stringification so that interpolating it in, say an auth header,
will return just the token.

This is for introspection purposes, so if something goes wrong, you can check
the response from your request and see the token that was used.

=cut

9008
