use strictures;

package WebService::GoogleAPI::Client::AuthStorage;

# ABSTRACT: JSON File Persistence for Google OAUTH Project and User Access Tokens

## is client->auth_storage
## or is Client->ua->auth_storage delegated as auth_storage to client

## or is UserAgent->credentials

use Moo::Role;

requires qw/refresh_token get_access_token_from_storage set_access_token_to_storage scopes/;



1;
