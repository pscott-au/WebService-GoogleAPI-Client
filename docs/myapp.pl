#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::JSON qw(decode_json encode_json);
use WebService::GoogleAPI::Client;
use Data::Dumper;

# Documentation browser under "/perldoc"
#plugin 'PODRenderer';
app->config(
    hypnotoad => {

    listen => ['http+unix://myapp.sock'],

#        proxy  => 1,
    },
);

my $config = {
  debug => 0,
  key => $ENV{GOOGLE_MAPS_KEY},  
  #input_address  =>  url_encode($ARGV[0]) || undef,
  get_nearby_places => 0,
};


my $gapi_client = WebService::GoogleAPI::Client->new( debug => $config->{debug}, gapi_json => 'gapi.json' ); ## , 
my $aref_token_emails = $gapi_client->auth_storage->storage->get_token_emails_from_storage;
#my $user              = $aref_token_emails->[0];                                                             ## default to the first user
#$gapi_client->user( $user );


get '/' => sub {
  my $c = shift;
  my $apis = ['Select a Google API',$gapi_client->list_of_available_google_api_ids()];
  $c->stash( all_apis_as_json => $apis ) ;
  $c->render(template => 'index'  )
};

get '/api_detail' => sub {
  my $c = shift;
  my $api_id = $c->param('api_id');
  #my $apis = [$gapi_client->list_of_available_google_api_ids()];
  $c->render( json => { api => $gapi_client->get_api_discovery_for_api_id( $api_id ),
                        methods => [ sort keys %{ $gapi_client->methods_available_for_google_api_id( $api_id ) } ],
                       } );
};

get '/endpoint_detail' => sub {
  my $c = shift;
  my $endpoint_id = $c->param('method_name');
  #my $apis = [$gapi_client->list_of_available_google_api_ids()];
  $c->render( json => describe_endpoint_as_json( $gapi_client,  $endpoint_id )  );
};



get '/test' => sub {
  my $c = shift;
  ## get a list of all apis 

  $c->render(template => 'index2',  one => 'one', fnar => encode_json( [$gapi_client->list_of_available_google_api_ids()] ) ) ;
};

get '/all_apis' => sub {
  my $c = shift;

};

## just a place to collect cpan google related moduels
get '/GOOGLE-CPAN-MODULES' => sub {
  my $c = shift;
  $c->render( json => {
  'Moo::Google' => 'Avoid this',
  'API::Google' => 'Avoid this',
  'Net::Google' => ' ',
  'Tie::Google' => '',
  'DBD::Google' => ' ',
  'Geo::Google' => '',
  'Google::DNS' => '',
  'Google::Plus ' => '',
  'REST::Google' => '',
  'Google::Chart' => '',
  'Google::OAuth - Maintains a database for Google Access Tokens' => '',
  'Google::Tasks - Manipulate Google/GMail Tasks' => 'I didn\'t use a Google API for this module. Instead, it basically scrapes JSON off Google. I found this to be far easier than using Google\'s API. I never intended this to be a real module, just something that I could use quickly/easily myself. I\'m only publishing this in case someone else might find it useful as-is. It\'s not well-tested and probably never will be. And Google could break this entire library by changing their JSON structure. Consequently, this module should probably not be used by anyone, ever.',
  'Google::Voice - Easy interface for google voice' => '',
  'Google::reCAPTCHA - A simple lightweight implementation of Google\'s reCAPTCHA for perl' => 'DEPREACTED - Google Replaced with reCAPTCHA v3',
  'Google::ProtocolBuffers - simple interface to Google Protocol Buffers' => '',
  'Mojo::JWT::Google' => '',
  'Geo::Coder::Google' => '',
  'Geo::Coder::Google::V3' => '',
  'WWW::Google::Drive' => '',


   } );
};


################################################################
=head2 C<check_api_endpoint_and_user_scopes>

describes the api-endpoing including parameters and whether
the Client user has access scopes.

=cut

sub describe_endpoint_as_json
{
    my ( $client, $api_endpoint  ) = @_;
    say "api endpoint = $api_endpoint";
    my $ret = {}; 
    my $api_spec = $client->get_api_discovery_for_api_id( $api_endpoint  ); ## only for base url

    $ret->{base_url} = $api_spec->{baseUrl};
     
    my $api_method_details = $client->extract_method_discovery_detail_from_api_spec( $api_endpoint );
    $api_method_details = { scopes=>[], parameterOrder=>[], parameters=>{} } unless defined $api_method_details;

    $api_method_details->{scopes} = [] unless defined $api_method_details->{scopes};

    my $scopes_txt = join("\n", @{$api_method_details->{scopes}} );
    $ret->{scopes} = $api_method_details->{scopes};

    $ret->{parameterOrder} = $api_method_details->{parameterOrder};

    $ret->{parameters} = [];

    foreach my $param ( sort keys %{$api_method_details->{parameters}}  )
    {
        my $param_data = { name => $param };
        foreach my $field (qw/description type  location required/) 
        {
            if (defined $api_method_details->{parameters}{$param}{$field} )
            {
                $param_data->{$field} = $api_method_details->{parameters}{$param}{$field};
            }
            else 
            {
              $param_data->{$field}  = '';
            }
        }
        push @{$ret->{parameters}}, $param_data;
    }
    return $ret;
}
################################################################

################################################################
sub display_api_summary_and_return_versioned_api_string
{
    my ( $client, $api_name, $version  ) = @_;
    $api_name =~ s/\..*$//smg;
    if ($api_name =~ /^([^:]*):(.*)$/xsm )
    {
        $api_name = $1;
        $version  = $2;
    }
    #say "api $api_name version $version";

    my $new_hash = {}; ## index by 'api:version' ( id )
    my $preferred_api_name = ''; ## this is set to the preferred version if described 
    my $text_table = Text::Table->new();

    foreach my $api ( @{ %{$client->discover_all()}{items} } )
    {
        # convert JSON::PP::Boolean to true|false strings
        if ( defined $api->{preferred} )
        {
            $api->{preferred}  = "$api->{preferred}";
            $api->{preferred}  = $api->{preferred} eq '0' ? 'no' : 'YES';
            
            if ( $preferred_api_name eq '' && $api->{preferred} eq 'YES' )
            {
                if (  $api->{id} =~ /$api_name/mx )
                {
                    $preferred_api_name = $api->{id} ;
                    $new_hash->{ $api_name } = $api;
                }
            }
        }
        #$new_hash->{ $api->{name} } = $api unless defined $new_hash->{ $api->{name} };
        $new_hash->{ $api->{id} } = $api;
        if (  $api->{name} =~ /$api_name/xm  )
        {
            foreach my $field (qw/title version preferred id  description discoveryRestUrl documentationLink name/)
            {
                #say qq{$field = $api->{$field}};
                $text_table->add( $field, $api->{$field}  );
            }
            $text_table->add(' ',' ');
        }
    }

    
    say "## Google $new_hash->{$api_name}{title} ( $api_name ) SUMMARY\n\n";
    say $text_table;
    
    if ( defined $version)
    {
        $api_name = "$api_name:$version";
    }
    else 
    {
        $api_name = $preferred_api_name;
    }
    say Dumper $new_hash->{$api_name}  if $client->{debug}; 
    
    return $api_name;
}




app->start;
__DATA__

@@ index2.html.ep
% layout 'default';
% title 'Welcome';
<h1>Welcome to the Mojolicious real-time web framework!</h1>
To learn more, you can browse through the documentation
<%= link_to 'here' => '/perldoc' %>.

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
  <p>Hello Peter2 <%=  $fnar %> </p>
</html>
