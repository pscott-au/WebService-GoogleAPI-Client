#!/usr/bin/perl

use strict;
use warnings;
use WebService::GoogleAPI::Client::Discovery;
use WebService::GoogleAPI::Client;
use Data::Dumper;
use JSON;
use Text::Table;
use JSON::PP::Boolean;
use Carp;
use CHI;
use feature 'say';
use Data::Printer;
use Mojo::Message::Response;
use Data::PrettyPrintObjects;

=head2 dev_blogger_example.pl


    https://developers.google.com/blogger/docs/3.0/getting_started


=cut



my $chi = CHI->new(
               driver         => 'File',
               #root_dir       => '/var/folders/0f/ps628sj57m90zqh9pqq846m80000gn/T/chi-driver-file',
               #depth          => 3,
               max_key_length => 512
           );

say( "CHI Root Directory = " . WebService::GoogleAPI::Client->new(chi => $chi)->discovery->chi->root_dir );
if ( my $x = $chi->get( "https://www.googleapis.com/discovery/v1/apis/gmail/v1/rest" ) )
#if ( my $x = $chi->get('https://www.googleapis.com/discovery/v1/apis') )
{
  #print Dumper $x;
  say "CHI has the discovery stored at " . $chi->path_to_key( "https://www.googleapis.com/discovery/v1/apis/gmail/v1/rest" )
} 
else 
{
    #my $le = WebService::GoogleAPI::Client::Discovery->new( chi => $chi );
    #my $no = $le->get_api_discovery_for_api_version({api=> 'blogger', version=>'v3'});
  #croak('fdfd');

  #my $y = WebService::GoogleAPI::Client->new(chi => $chi)->discovery->get_api_discovery_for_api_version({api=> 'blogger', version=>'v3'});
                    #$chi->set( "https://www.googleapis.com/discovery/v1/apis/gmail/v1/rest", $y, '30d');
                    #say $chi->path_to_key( "https://www.googleapis.com/discovery/v1/apis/gmail/v1/rest" )
  #print Dumper $y;

}
#exit;

## nb - not all calls below use the agent - some are direct class calls
my $gapi_agent = WebService::GoogleAPI::Client->new( debug => 1, chi => $chi, gapi_json=>'./gapi.json', user=> 'peter@shotgundriver.com'  );


## AVAILABLE API IDS
if ( 1 == 0 )
{
  my @apis = WebService::GoogleAPI::Client->new->list_of_available_google_api_ids();
  say "AVAILABLE GOOGLE SERVICE IDs = " . join( ", ", @apis );
  say "Total count = " . scalar( @apis );
  exit;
}


my $blogger_api = WebService::GoogleAPI::Client->new->methods_available_for_google_api_id( 'blogger' );

#say "Available api end-points for gmail = \n\t" . join("\n\t", keys %$blogger_api);
say "Available api end-points for blogger = \n\t" . join( ",", keys %$blogger_api ) . "\n\n";
say "blogger includes a total of " . scalar( keys %$blogger_api ) . ' methods';

#say Dumper $gapi_agent->discovery->get_api_discovery_for_api_id( 'blogger.blogs.listByUser') ;
say '-' x 50;
say "blogger.blogs.listByUser";
say '-' x 50;
p( %{ $gapi_agent->extract_method_discovery_detail_from_api_spec( 'blogger.blogs.listByUser') } );
exit;


my $r =   $gapi_agent->api_query( 
                            api_endpoint_id => 'blogger.blogs.listByUser',
                            options    => { userId => 'self' },
                        );

#print Dumper $r;
#
#print PPO( $r->json->{items}[0] );


p(  %{$r->json->{items}[0]} );


# blogger.blogs.listByUser
#exit;


## Get a list of all blogs for the user

## do we have a match ?

## get a list of all the blog posts ..

## iterate through the blog posts looking for any variables to interpolate

## if find one then interpolate and post the update 

