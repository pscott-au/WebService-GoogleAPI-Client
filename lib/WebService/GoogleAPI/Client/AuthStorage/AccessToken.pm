package WebService::GoogleAPI::Client::AuthStorage::AccessToken;

use Moo;

use overload '""' => sub { shift->token };

has [ qw/token user/ ] =>
  is => 'ro',
  required => 1;


9008
