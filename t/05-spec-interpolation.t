use strict;
use warnings;
use Test2::V0;

use lib 't/lib';
use TestTools qw/DEBUG gapi_json user/;
use WebService::GoogleAPI::Client;

my $gapi = WebService::GoogleAPI::Client->new(
  debug => DEBUG, gapi_json => gapi_json, user => user);

my $options = {
  api_endpoint_id => 'drive.files.list',
  options => {
    fields => 'files(id,name,parents)'
  }
};

sub build_req {
  $gapi->_process_params(shift);
}

build_req($options);
is $options->{path}, 
'https://www.googleapis.com/drive/v3/files?fields=files%28id%2Cname%2Cparents%29',
'Can interpolate globally available query parameters';

$options = {
  api_endpoint_id => "sheets:v4.spreadsheets.values.update",  
  options => { 
    spreadsheetId => 'sner',
    includeValuesInResponse => 'true',
    valueInputOption => 'RAW',
    range => 'Sheet1!A1:A2',
    'values' => [[99],[98]]
  },
  cb_method_discovery_modify => sub { 
    my  $meth_spec  = shift; 
    $meth_spec->{parameters}{valueInputOption}{location} = 'path';
    $meth_spec->{path} .= "?valueInputOption={valueInputOption}";
    return $meth_spec;
  }
};

build_req($options);

is $options->{path}, 'https://sheets.googleapis.com/v4/spreadsheets/sner/values/Sheet1!A1:A2?valueInputOption=RAW&includeValuesInResponse=true', 
'interpolation works with user fiddled path, too';

$options = {
  api_endpoint_id => "sheets:v4.spreadsheets.values.batchGet",  
  options => { 
    spreadsheetId => 'sner',
    ranges => ['Sheet1!A1:A2', 'Sheet1!A3:B5'],
  },
};
build_req($options);
is $options->{path}, 
'https://sheets.googleapis.com/v4/spreadsheets/sner/values:batchGet?ranges=Sheet1%21A1%3AA2&ranges=Sheet1%21A3%3AB5', 
'interpolates arrayref correctly' ;

subtest 'funky stuff in the jobs api' => sub {
    # TODO - let's change this to make sure this check doesn't needa happen
    return fail 'has the scopes', <<MSG
Need access to the scope https://www.googleapis.com/auth/jobs 
or https://www.googleapis.com/auth/cloud-platform

If you're supplying your own credentials, please authorize them for said scopes
(no network access is made, so you can just write it into the gapi.json)
MSG
    unless $gapi->has_scope_to_access_api_endpoint('jobs.projects.jobs.delete');

  subtest 'Testing {+param} type interpolation options' => sub {
    my $interpolated = 'https://jobs.googleapis.com/v3/projects/sner/jobs';

    $options = { api_endpoint_id => 'jobs.projects.jobs.delete',
      options => {name => 'projects/sner/jobs/bler'} };
    $gapi->_process_params( $options );
    is $options->{path}, "$interpolated/bler", 
      'Interpolates a {+param} that matches the spec pattern';

    $options = 
    { api_endpoint_id => 'jobs.projects.jobs.list',
      options => { parent => 'sner' } };
    $gapi->_process_params( $options );
    is $options->{path}, $interpolated, 
      'Interpolates just the dynamic part of the {+param}, when not matching the spec pattern';

    $options = 
    { api_endpoint_id => 'jobs.projects.jobs.delete',
      options => {projectsId => 'sner', jobsId => 'bler'} };
    $gapi->_process_params( $options );

    is $options->{path}, "$interpolated/bler", 
      'Interpolates params that match the flatName spec (camelCase)';

    $options = 
    { api_endpoint_id => 'jobs.projects.jobs.delete',
      options => {projects_id => 'sner', jobs_id => 'bler'} };
    $gapi->_process_params( $options );

    is $options->{path}, "$interpolated/bler", 
      'Interpolates params that match the names in the api description (snake_case)';


  };


  my @errors;
  subtest 'Checking for proper failure with {+params} in unsupported ways' => sub {
      $options = 
      { api_endpoint_id => 'jobs.projects.jobs.delete',
        options => { name => 'sner' } };
      @errors = $gapi->_process_params( $options );
      is $errors[0], 'Not enough parameters given for {+name}.', 
        "Fails if you don't supply enough values to fill the dynamic parts of {+param}";

      $options = 
      { api_endpoint_id => 'jobs.projects.jobs.delete',
        options => { jobsId => 'sner' } };
      @errors = $gapi->_process_params( $options );
      is $errors[0], 'Missing a parameter for {projectsId}.', 
        "Fails if you don't supply enough values to fill the flatPath";

  };

};




done_testing;
