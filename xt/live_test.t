use Test2::V0;
use lib 't/lib';

# TODO - make a simple test which creates a file, lists it, then deletes it, for
# both a service account and a regular account.

use WebService::GoogleAPI::Client;
use Mojo::File qw/path/;

bail_out <<NEEDS_CREDS unless my $root = $ENV{GAPI_XT_REAL_CREDS};
This test requires real credentials with access to the
https://www.googleapis.com/auth/drive scope. Please set the GAPI_XT_REAL_CREDS
environment variable to the directory containing a valid gapi.json and service.json
file with the requisite access. See CONTRIBUTING for more info.
NEEDS_CREDS

bail_out <<NEEDS_USER unless my $user = $ENV{GAPI_XT_USER};
This test does real network access to create and remove a file in your google
drive. Please supply the email account that you have valid credentials for in
the GAPI_XT_USER evironment variable.
NEEDS_USER


my $u = WebService::GoogleAPI::Client->new(
  gapi_json => path($root)->child('gapi.json')->to_string
);

my $s = WebService::GoogleAPI::Client->new(
  service_account => path($root)->child('service.json')->to_string
);



done_testing;
