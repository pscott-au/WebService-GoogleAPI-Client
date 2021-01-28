use Test2::V0;

# TODO - make a simple test which creates a file, lists it, then deletes it, for
# both a service account and a regular account.

use WebService::GoogleAPI::Client;

bail_out <<NEEDS_CREDS unless my $user_creds = $ENV{GAPI_XT_USER_CREDS};
This test requires real credentials with access to the
https://www.googleapis.com/auth/drive scope. Please set the GAPI_XT_USER_CREDS
environment variable to the gapi.json file and user email joined by a :

See CONTRIBUTING for more details
NEEDS_CREDS

bail_out <<NEEDS_USER unless my $service_creds = $ENV{GAPI_XT_SERVICE_CREDS};
This test requires real service account credentials with access to 
https://www.googleapis.com/auth/drive scope (which I think is there by default).
Please set the GAPI_XT_SERVICE_CREDS environment variable to your service account file.

See CONTRIBUTING for more details
NEEDS_USER


my ($path, $email) = split /:/, $user_creds;
my $u = WebService::GoogleAPI::Client->new(
  gapi_json => $path, user => $email
);

my $s = WebService::GoogleAPI::Client->new(
  service_account => $service_creds
);



done_testing;
