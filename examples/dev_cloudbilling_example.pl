#!/usr/bin/env perl

use WebService::GoogleAPI::Client;

use Data::Dumper qw (Dumper);
use utf8;
use open ':std', ':encoding(UTF-8)';    ## allows to print out utf8 without errors
use feature 'say';
use JSON;
use Carp;
use strictures;


=head1 CLOUD BILLING API EXAMPLE


https://www.googleapis.com/auth/cloud-platform

=cut

if ( my @x = test_function() )
{
  say 'ok' . @x;
}
else
{
  say 'no ok' . @x;
}

sub test_function
{
  #return carp('foo'); ## returns 1
  carp( 'bar' );
  return;
}
