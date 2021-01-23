package WebService::GoogleAPI::Client::AccessToken;

use Moo;

use overload '""' => sub { shift->token };

has [ qw/token user scopes/ ] =>
  is => 'ro',
  required => 1;


9008
