#!/usr/bin/env perl

use WebService::GoogleAPI::Client;

use Data::Dump qw (pp dd);
use utf8;
use open ':std', ':encoding(UTF-8)';    ## allows to print out utf8 without errors
# binmode(STDOUT, ":utf8"); ## to allow output of utf to terminal - see also http://perldoc.perl.org/perlrun.html#-C
use feature 'say';
use JSON;
use Carp;
use strict;
use warnings;
use Text::Table;


#my $sub1 = sub { my ( $x) = @_; print "hello $x\n" };
#&$sub1('fnar');
#print ref($sub1);
#exit;

require './EXAMPLE_HELPERS.pm'; ## check_api_endpoint_and_user_scopes() and display_api_summary_and_return_versioned_api_string()

my $config = {
  api => 'sheets', # sheets:v4
  debug => 01,
  sheet_id => $ENV{GOOGLE_SHEET_ID} || $ARGV[0], #  @ARGV[0] - The sheet ID can be obtained using the Drive API or you can copy the ID from the URL if open sheet in browser
  sheet_update_range => 'Sheet1!A1:A2',
  do => { ## allows to filter which blocks of example code are run
      '' => 0,
      'sheets.spreadsheets.values.update' => 1,

  }
};


=pod

=head1 sheets_example.pl

    perl sheets_example.pl <SHEET_ID>

The sheet ID can be obtained using the Drive API or you can copy the ID from the URL if open sheet in browser

=head2 PRE-REQUISITES


Setup a Google Project in the Google Console and add the Translate API Library. You may need 
to enable billing to access Google Cloud Services.

Projects require the API to be enabled for the project in the APIs console. L<https://console.cloud.google.com/apis/library/sheets.googleapis.com>

sheets.googleapis.com


Setup an OAUTH Credential set and feed this into the CLI goauth 
included in WebService::GoogleAPI::Client and use the tool to authorise
your user to access the project which will also create the local gapi.json config.

assumes gapi.json configuration in working directory with scoped project and user authorization
  


=head2 RELEVANT SCOPES

=over 2

=item https://www.googleapis.com/auth/drive

=item https://www.googleapis.com/auth/drive.file

=item https://www.googleapis.com/auth/spreadsheets

=back


=head2 GOOGLE API LINKS

=over 2

=item L<https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets>

=item L<https://developers.google.com/apis-explorer/>

=back 

=cut



=head2 SHEETS V4 API ENDPOINTS

	sheets:v4.spreadsheets.batchUpdate
	sheets:v4.spreadsheets.create
	sheets:v4.spreadsheets.developerMetadata.get
	sheets:v4.spreadsheets.developerMetadata.search
	sheets:v4.spreadsheets.get
	sheets:v4.spreadsheets.getByDataFilter
	sheets:v4.spreadsheets.sheets.copyTo
	sheets:v4.spreadsheets.values.append
	sheets:v4.spreadsheets.values.batchClear
	sheets:v4.spreadsheets.values.batchClearByDataFilter
	sheets:v4.spreadsheets.values.batchGet
	sheets:v4.spreadsheets.values.batchGetByDataFilter
	sheets:v4.spreadsheets.values.batchUpdate
	sheets:v4.spreadsheets.values.batchUpdateByDataFilter
	sheets:v4.spreadsheets.values.clear
	sheets:v4.spreadsheets.values.get
	sheets:v4.spreadsheets.values.update


=head2 LIST ALL SHEETS

V3 - OLDER
    As described at https://developers.google.com/sheets/api/v3/worksheets#retrieve_a_list_of_spreadsheets
    https://spreadsheets.google.com/feeds/spreadsheets/private/full

V4 - CURRENT
    - need to use Google Drive as per https://stackoverflow.com/a/37881096/2779629
    - and in docs - https://developers.google.com/sheets/api/guides/migration#list_spreadsheets_for_the_authenticated_user
    


=cut

my $DEBUG = 1;


##    BASIC CLIENT CONFIGURATION

if   ( -e './gapi.json' ) { say "auth file exists" }
else                      { croak( 'I only work if gapi.json is here' ); }
;    ## prolly better to fail on setup ?
my $gapi_agent        = WebService::GoogleAPI::Client->new( debug => $DEBUG, gapi_json => 'gapi.json' );
my $aref_token_emails = $gapi_agent->auth_storage->storage->get_token_emails_from_storage;
my $user              = $aref_token_emails->[0];                                                             ## default to the first user
$gapi_agent->user( $user );

say "Running tests with default user email = $user";
say 'Root cache folder: ' . $gapi_agent->discovery->chi->root_dir();                                         ## cached content temporary directory


my $gapi_client = $gapi_agent;

####
####
####            DISPLAY AN OVERVIEW OF THE API VERSIONS 
####            AND SELECT THE PREFERRED VERSION IF NOT SPECIFIED
####

#display_api_summary_and_return_versioned_api_string( $gapi_client, $config->{api}, 'v1beta2' );
my $versioned_api = display_api_summary_and_return_versioned_api_string( $gapi_client, $config->{api} );

say "Versioned version of API = $versioned_api ";
#exit;
## interestingly an auth'd request is denied without the correct scope .. so can't use that to find the missing scope :)
my $methods = $gapi_client->methods_available_for_google_api_id( $versioned_api );
 say join("\n\t", "DNS API END POINTS:\n", sort keys %$methods );
#exit;



if ( $config->{do}{'sheets.spreadsheets.values.update'})
{
    #############################################################################
    ## drive:v3
    ####
    ####
    ####            sheets.spreadsheets.values.update - 
    ####            https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets.values/update

    check_api_endpoint_and_user_scopes( $gapi_client, "$versioned_api.spreadsheets.values.update" );


    ####
    ####
    ####            EXECUTE API - sheets.spreadsheets.values.update
    ####
    ####

    my $options = { 
                            spreadsheetId => $config->{sheet_id},
                            valueInputOption => 'RAW',
                            range => $config->{sheet_update_range},
                            majorDimension => 'ROWS',
                            'values' => [[99],[98]],
                            #responseValueRenderOption => 'FORMATTED_VALUE',
                            
                    } ;

    my $r = $gapi_client->api_query(  api_endpoint_id => "$versioned_api.spreadsheets.values.update",  
    #path => 'v4/spreadsheets/{spreadsheetId}/values/{range}?valueInputOption={valueInputOption}&responseValueRenderOption=FORMATTED_VALUE',
                                    options => $options,
                                   # cb_method_discovery_modify => sub { 
                                   #   my  $meth_spec  = shift; 
                                   #   $meth_spec->{parameters}{valueInputOption}{location} = 'path';
                                   #   $meth_spec->{path} = "v4/spreadsheets/{spreadsheetId}/values/{range}?valueInputOption={valueInputOption}";
                                   #   return $meth_spec;
                                   # }
                                    );
    print dd  $r->json; # ->json;
    ############################################################################
}


=head2 SEE ALSO

=over 2

=item Net::Google::Spreadsheets::V4

=back

=cut