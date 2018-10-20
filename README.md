[![Build Status](https://travis-ci.org/pscott-au/WebService-GoogleAPI-Client.svg?branch=master)](https://travis-ci.org/pscott-au/WebService-GoogleAPI-Client)
[![Coverage Status](https://coveralls.io/repos/github/pscott-au/WebService-GoogleAPI-Client/badge.svg?branch=master)](https://coveralls.io/github/pscott-au/WebService-GoogleAPI-Client?branch=master)
[![CPAN Version](https://img.shields.io/cpan/v/WebService-GoogleAPI-Client.svg)](http://search.cpan.org/~localshop/WebService-GoogleAPI-Client/lib/WebService/GoogleAPI/Client.pm)


![Perl Google APIs Client Library](https://pscott-au.github.io/WebService-GoogleAPI-Client/perl-google-apis-client-library.png)

# NAME

WebService::GoogleAPI::Client - Perl Google API Services OAUTH Client.

# VERSION

version 0.12

# SYNOPSIS

Provides client access to [Google API V.1](https://developers.google.com/discovery/v1) Service End-Points using a user-agent that handles OAUTH2 authentication and access control and provides helpers to cache API Discovery specifications.

The guiding principal is to minimise the conceptual load when using the Client agent for users who want to make calls directly, but also make available functions to help explore unfamiliar API endpoints by offering optional validation etc against the latest published Google API Discovery specifications.


NB: To create or modify an authorization configuration file with scope and user tokens in current folder run _goauth_ CLI tool to interactively create the JSON configuration and launch a local HTTP server to acquire authenticated access permissions with a Google email account. 

![goauth screen capture](https://pscott-au.github.io/WebService-GoogleAPI-Client/goauth-login-cap.gif)

See ````perldoc goauth```` for more detail.


````perl
    use WebService::GoogleAPI::Client;
    use Data::Dumper;


    ## assumes gapi.json configuration in working directory with scoped project and user authorization
    
    my $gapi_client = WebService::GoogleAPI::Client->new( debug => 1, gapi_json => './gapi.json', user=> 'peter@pscott.com.au' );


    ## Completely manually constructed API End-Point Request to obtain Perl Data Structure converted from JSON response.
    my $res = $gapi_client->api_query(
          method => 'get',
          path => 'https://www.googleapis.com/calendar/users/me/calendarList',
        )->json;


    ## using dotted API Endpoint id to invoke helper validation and default value interpolations etc to send email to self
    use Email::Simple;    ## RFC2822 formatted messages
    use MIME::Base64;
    my $my_email_address = 'peter@shotgundriver.com'


    my $raw_email_payload = encode_base64( Email::Simple->create( header => [To => $my_email_address, 
                                                                             From => $my_email_address, 
                                                                             Subject =>"Test email from '$my_email_address' ",], 
                                                                             body => "This is the body of email to '$my_email_address'", 
                                                                )->as_string 
                                        );

    $gapi_client->api_query( 
                            api_endpoint_id => 'gmail.users.messages.send',
                            options    => { raw => $raw_email_payload },
                        );


    ## TEXT TO SPEECH EXAMPLE
    my $text_to_speech_request_options =  {
            'input' => {
            'text' => 'Using the Web-Services-Google-Client Perl module, it is now a simple matter to access all of the Google API Resources in a consistent manner.'
            },
            'voice' => {
            'languageCode' => 'en-gb',
            'name' => 'en-GB-Standard-A',
            'ssmlGender' => 'FEMALE'
            },
            'audioConfig' => {
            'audioEncoding'=> 'MP3'
            }
        };

    ## Using this API requires authorised https://www.googleapis.com/auth/cloud-platform scope 

    if ( 0 ) ## use a full manually constructed non validating standard user agent query builder approach ( includes auto O-Auth token handling )
    {
        $r = $gapi_client->api_query( 
            method => 'POST',
            path   => 'https://texttospeech.googleapis.com/v1/text:synthesize',
            options => $text_to_speech_request_options
        ) ;

    }
    else  ## use the api end-point id and take full advantage of pre-submission validation etc
    {
        $r = $gapi_client->api_query( 
            api_endpoint_id => 'texttospeech.text.synthesize', 
            # method => 'POST',                                                   ## not required as determined from API SPEC
            # path   => 'https://texttospeech.googleapis.com/v1/text:synthesize', ## not required as determined from API SPEC
            options => $text_to_speech_request_options
        ) ;
        ## NB - this approach will also autofill any defaults that aren't defined 
        ##      confirm that the user has the required scope before submitting to Google.
        ##      confirms that all required fields are populated
        ##      where an error is detected - result is a 418 code ( I'm a teapot ) with the body containing the error descriptions

    }

    if ( $r->is_success ) ## $r is a standard Mojo::Message::Response instance
    {
    my $returned_data =  $r->json; ## convert from json to native hashref - result is a hashref with a key 'audioContent' containing synthesized audio in base64-encoded MP3 format
    my $decoded_mp3 = decode_base64( $returned_data->{audioContent} );

    my $tmp = File::Temp->new( UNLINK => 0, SUFFIX => '.mp3' );
    print $tmp  $decoded_mp3;
    
    print "ffplay -nodisp  -autoexit  $tmp\n";
    `ffplay -nodisp  -autoexit  $tmp`;
    close($tmp);

    # ffplay -nodisp  -autoexit  ~/Downloads/en-GB-Standard-A.mp3
    }
    else 
    {
        if ( $r->code eq '418' )
        {
            print qq{Cool - I'm a teapot - this was caught ebfore sending the request through to Google \n};
            print $r->body;
        }
        else ## other error - should appear in warnings but can inspect $r for more detail
        {
            print Dumper $r;
        }
        
    }



````



# INSTALLATION

## From Repository Source Root Using Dist::Zilla

The code in this repository uses [Dist::Zilla](http://dzil.org/) Build System to assist package building and creation of Tarball and CPAN distribution. Curiously the [Github Repo](https://github.com/rjbs/dist-zilla/) describes itself as '*scary tools for building CPAN distributions*'

````shell
    sudo dzil install
````

## Install from Tarball

````
    
    wget https://dev.pscott.com.au/WebService-Google-Client-latest.tar.gz
    tar -zxvf WebService-Google-Client-latest.tar.gz
    rm WebService-Google-Client-latest.tar.gz
    cd   WebService-Google-Client-*
    perl Makefile.PL
    make test
    sudo make install

    
````

## Install from CPAN

  sudo cpanm WebService::GoogleAPI::Client


## TYPICAL USAGE QUICKSTART

### PRE-REQUISITES

* Requires a suitably configured Project in Google Admin Console with scopes and OAUTH Client
* Requires a local project configuration file that can be generated with the included *goauth* CLI Tool (perldoc goauth for more detail )

````perl
    use feature 'say';
    use WebService::GoogleAPI::Client;

    my $gapi = WebService::GoogleAPI::Client->new(debug => 0);
    $gapi->auth_storage->setup( { type => 'jsonfile', path => './gapi.json' } );

    ## This idiom selects the first authorised user from gapi.json 
    my $aref_token_emails = $gapi->auth_storage->storage->get_token_emails_from_storage;
    my $user = $aref_token_emails->[0];
    print "Running tests with default user email = $user\n";
    $gapi->user($user);

    ## Get all emails sent to $user newer than 1 day
    my $cl =   $gapi->api_query({
        method => 'get',
        path       => "https://www.googleapis.com/gmail/v1/users/me/messages?q=newer_than:1d;to:$user", 
    });

    if ($cl->code eq '200') ## Mojo::Message::Response
    {
        foreach my $msg ( @{ $cl->json->{messages} } )
        {
            say Dumper $msg;
        }

    }

````


# KEY FEATURES

- API Discovery with local caching using CHI File
- OAUTH app credentials (client\_id, client\_secret, users access\_token && refresh\_token) storage stored in local gapi.json file
- Automatic access\_token refresh (if user has refresh\_token) and saving refreshed token to storage
- CLI tool (_goauth_) with lightweight HTTP server to simplify config OAuth2 configuration, sccoping, authorization and obtaining access\_ and refresh\_ tokens

## TODO: 

- UNDER REVIEW


# SEE ALSO

- [Moo::Google](https://metacpan.org/pod/Moo::Google) - The original code base later forked into [WebService::Google](https://metacpan.org/pod/WebService::Google) but is heading in a different direction
- [Google Swagger API https:](https:///github.com/APIs-guru/google-discovery-to-swagger) 

# AUTHORS

- Peter Scott <peter@pscott.com.au>

# CONTRIBUTORS

- Pavel Serikov <pavelsr@cpan.org> provided the original source code in Moo::Google

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2018 by Peter Scott and others.

This is free software, licensed under:

      The Apache License, Version 2.0, January 2004
