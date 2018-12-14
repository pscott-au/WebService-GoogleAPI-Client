use strict;
use warnings;
use Test::More;
use Cwd;

use WebService::GoogleAPI::Client;

my $dir   = getcwd;
my $DEBUG = $ENV{GAPI_DEBUG_LEVEL} || 0;        ## to see noise of class debugging
my $default_file = $ENV{ 'GOOGLE_TOKENSFILE' } || "$dir/../../gapi.json";    ## assumes running in a sub of the build dir by dzil
$default_file = "$dir/../gapi.json" unless -e $default_file;                 ## if file doesn't exist try one level up ( allows to run directly from t/ if gapi.json in parent dir )

plan skip_all => 'No service configuration - set $ENV{GOOGLE_TOKENSFILE} or create gapi.json in dzil source root directory'  unless -e $default_file;

ok( my $gapi = WebService::GoogleAPI::Client->new( debug => $DEBUG, gapi_json => $default_file ), 'Creating test session instance of WebService::GoogleAPI::Client' );

my %options;

subtest 'Testing {+param} type interpolation options' => sub {
    plan skip_all => <<MSG
Need access to the scope https://www.googleapis.com/auth/jobs  
or https://www.googleapis.com/auth/cloud-platform
MSG
    unless $gapi->has_scope_to_access_api_endpoint('jobs.projects.jobs.delete');

  my $interpolated = 'https://jobs.googleapis.com/v3/projects/sner/jobs';

  %options = ( api_endpoint_id => 'jobs.projects.jobs.delete',
    options => {name => 'projects/sner/jobs/bler'} );
  $gapi->_process_params_for_api_endpoint_and_return_errors( \%options );
  is $options{path}, "$interpolated/bler", 
    'Interpolates a {+param} that matches the spec pattern';

  %options = 
  ( api_endpoint_id => 'jobs.projects.jobs.list',
    options => { parent => 'sner' } );
  $gapi->_process_params_for_api_endpoint_and_return_errors( \%options );
  is $options{path}, $interpolated, 
    'Interpolates just the dynamic part of the {+param}, when not matching the spec pattern';

  %options = 
  ( api_endpoint_id => 'jobs.projects.jobs.delete',
    options => {projectsId => 'sner', jobsId => 'bler'} );
  $gapi->_process_params_for_api_endpoint_and_return_errors( \%options );

  is $options{path}, "$interpolated/bler", 
    'Interpolates params that match the flatName spec (camelCase)';

  %options = 
  ( api_endpoint_id => 'jobs.projects.jobs.delete',
    options => {projects_id => 'sner', jobs_id => 'bler'} );
  $gapi->_process_params_for_api_endpoint_and_return_errors( \%options );

  is $options{path}, "$interpolated/bler", 
    'Interpolates params that match the names in the api description (snake_case)';


};

my @errors;
subtest 'Checking for proper failure with {+params} in unsupported ways' => sub {
    plan skip_all => <<MSG
Need access to the scope https://www.googleapis.com/auth/jobs 
or https://www.googleapis.com/auth/cloud-platform
MSG
    unless $gapi->has_scope_to_access_api_endpoint('jobs.projects.jobs.delete');


    %options = 
    ( api_endpoint_id => 'jobs.projects.jobs.delete',
      options => { name => 'sner' } );
    @errors = $gapi->_process_params_for_api_endpoint_and_return_errors( \%options );
    is $errors[0], 'Not enough parameters given for {+name}.', 
      "Fails if you don't supply enough values to fill the dynamic parts of {+param}";

    %options = 
    ( api_endpoint_id => 'jobs.projects.jobs.delete',
      options => { jobsId => 'sner' });
    @errors = $gapi->_process_params_for_api_endpoint_and_return_errors( \%options );
    is $errors[0], 'Missing a parameter for {projectsId}.', 
      "Fails if you don't supply enough values to fill the flatPath";

};






done_testing;
