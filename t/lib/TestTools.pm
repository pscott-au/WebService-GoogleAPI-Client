package TestTools;
use strict;
use warnings;

use Exporter::Shiny qw/ gapi_json DEBUG user has_credentials set_credentials/;
use Mojo::File qw/curfile path/;

my $gapi;
#try and find a good gapi.json to use here. Check as follows:
#  1) first try whatever was set in the ENV variable
#  2) the current directory
#  3) the directory BELOW the main dir for the project, so dzil's
#     author tests can find the one in our main folder 
#  4) the main dir of this project
#  5) the fake one in the t/ directory
$gapi = path($ENV{GOOGLE_TOKENSFILE} || './gapi.json');
$gapi = curfile->dirname->dirname->dirname->sibling('gapi.json')
  unless $gapi->stat;
$gapi = curfile->dirname->dirname->sibling('gapi.json')
  unless $gapi->stat;
$gapi = curfile->dirname->sibling('gapi.json')
  unless $gapi->stat;

sub gapi_json {
  return "$gapi";
}
sub user { $ENV{GMAIL_FOR_TESTING} }

sub has_credentials { $gapi->stat && user }
sub set_credentials {
  my ($obj) = @_;
  $obj->ua->auth_storage->setup({ type => 'jsonfile', path => "$gapi" });
  $obj->ua->user(user)
}


sub DEBUG { $ENV{GAPI_DEBUG_LEVEL} // 0 }

9033
