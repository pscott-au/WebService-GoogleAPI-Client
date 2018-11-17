#!/usr/bin/env perl

use strictures;
## use Crypt::JWT qw(encode_jwt); -- couldn't get this to work
use Data::Dump qw/pp/;
use feature 'say';
use LWP::UserAgent;
use JSON;
use Mojo::File;
use Mojo::JWT; ## there is also Mojo::JWT::Google but the cpan version is broken - pull request submitted but is easy enough to use parent Mojo::JWT

my $config = {
    path => $ARGV[0] // '/Users/peter/Downloads/computerproscomau-b9f59b8ee34a.json',
    scopes => $ARGV[1] //  'https://www.googleapis.com/auth/plus.business.manage https://www.googleapis.com/auth/compute'
};

my $jwt = mojo_jwt_from_json_or_croak( $config->{path}, $config->{scopes} );
my $ua = LWP::UserAgent->new(); #WWW::Mechanize->new( autocheck => 1 ); 

my $response = $ua->post('https://www.googleapis.com/oauth2/v4/token', { 'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer', 
     'assertion' =>  $jwt }
     ); 

if ($response->is_success) 
{
    print $response->decoded_content;
}
else 
{
    print STDERR $response->status_line, "\n";
}
exit;

#######################################################################
sub mojo_jwt_from_json_or_croak
{
  my ( $path, $scope ) = @_;
  croak("No path provided") if not defined $path;
  croak("$path no available") if not -f $path;
  my $json = decode_json( Mojo::File->new($path)->slurp );
  croak("No Private key in $path") if not defined $json->{private_key};
  croak("Not a service account") if $json->{type} ne 'service_account';
  my $jwt = Mojo::JWT->new();
  $jwt->algorithm('RS256');
  $jwt->secret($json->{private_key});

  $jwt->claims( {
      iss => $json->{client_email},
      scope => $scope,
      aud   => 'https://www.googleapis.com/oauth2/v4/token',   
      iat => time(),
      exp => time()+3600   
  } );
  $jwt->set_iat( 1 );
  return $jwt->encode;
}
#######################################################################


=pod

POST https://www.googleapis.com/oauth2/v4/token

grant_type	Use the following string, URL-encoded as necessary: urn:ietf:params:oauth:grant-type:jwt-bearer
assertion	The JWT, including signature.

POST /oauth2/v4/token HTTP/1.1
Host: www.googleapis.com
Content-Type: application/x-www-form-urlencoded

grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI3NjEzMjY3OTgwNjktcjVtbGpsbG4xcmQ0bHJiaGc3NWVmZ2lncDM2bTc4ajVAZGV2ZWxvcGVyLmdzZXJ2aWNlYWNjb3VudC5jb20iLCJzY29wZSI6Imh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvcHJlZGljdGlvbiIsImF1ZCI6Imh0dHBzOi8vYWNjb3VudHMuZ29vZ2xlLmNvbS9vL29hdXRoMi90b2tlbiIsImV4cCI6MTMyODU3MzM4MSwiaWF0IjoxMzI4NTY5NzgxfQ.ixOUGehweEVX_UKXv5BbbwVEdcz6AYS-6uQV6fGorGKrHf3LIJnyREw9evE-gs2bmMaQI5_UbabvI4k-mQE4kBqtmSpTzxYBL1TCd7Kv5nTZoUC1CmwmWCFqT9RE6D7XSgPUh_jF1qskLa2w0rxMSjwruNKbysgRNctZPln7cqQ


=cut

=pod
Required claims
The required claims in the JWT claim set are shown below. They may appear in any order in the claim set.

Name	Description
iss	    The email address of the service account.
scope	A space-delimited list of the permissions that the application requests.
aud	    A descriptor of the intended target of the assertion. When making an access token request this value is always https://www.googleapis.com/oauth2/v4/token.
exp	    The expiration time of the assertion, specified as seconds since 00:00:00 UTC, January 1, 1970. This value has a maximum of 1 hour after the issued time.
iat	    The time the assertion was issued, specified as seconds since 00:00:00 UTC, January 1, 1970.

=cut

