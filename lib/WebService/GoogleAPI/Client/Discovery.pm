use strictures;

package WebService::GoogleAPI::Client::Discovery;

# ABSTRACT: Google API discovery service

=head2 MORE INFORMATION

L<https://developers.google.com/discovery/v1/reference/>

=head2 SEE ALSO

Not using Swagger but it is interesting - 
L<https://github.com/APIs-guru/openapi-directory/tree/master/APIs/googleapis.com> for Swagger Specs.

L<Google::API::Client> - contains code for parsing discovery structures 

includes a chi property that is an instance of CHI using File Driver to cache discovery resources for 30 days

say $client-dicovery->chi->root_dir(); ## provides full file path to temp storage location used for caching

=head2 TODO

=over 2

=item * handle 403 (Daily Limit for Unauthenticated Use Exceeded)

errors when reqeusting a discovery resource for a service but do we have access to authenticated reqeusts?

=back

=cut

use Moo;
use Carp;
use WebService::GoogleAPI::Client::UserAgent;
use List::Util qw/uniq reduce/;
use Hash::Slice qw/slice/;
use Data::Dump qw/pp/;
use CHI;

has ua => (
  is      => 'rw',
  default => sub { WebService::GoogleAPI::Client::UserAgent->new }
);
has debug => (is => 'rw', default => 0);
has 'chi' => (
  is      => 'rw',
  default => sub { CHI->new(driver => 'File', namespace => __PACKAGE__) },
  lazy    => 1
);    ## i believe that this gives priority to param if provided ?
has 'stats' => is => 'rw',
  default   => sub { { network => { get => 0 }, cache => { get => 0 } } };

=head1 METHODS

=head2 get_with_cache

  my $hashref = $disco->get_with_cache($url, $force, $authenticate)

Retrieves the given API URL, retrieving and caching the returned
JSON. If it gets a 403 Unauthenticated error, then it will try
again using the credentials that are save on this instances 'ua'.

If passed a truthy value for $force, then will not use the cache.
If passed a truthy value for $authenticate, then will make the
request with credentials.

=cut

sub get_with_cache {
  my ($self, $key, $force, $authorized) = @_;

  my $expiration = $self->chi->get_expires_at($key) // 0;

  my $will_expire = $expiration - time();
  if ($will_expire > 0 && not $force) {
    carp "discovery_data cached data expires in $will_expire seconds"
      if $self->debug > 2;
    my $ret = $self->chi->get($key);
    croak 'was expecting a HASHREF!' unless ref $ret eq 'HASH';
    $self->stats->{cache}{get}++;
    return $ret;
  } else {
    my $ret;
    if ($authorized) {
      $ret = $self->ua->validated_api_query($key);
      $self->stats->{network}{authorized}++;
    } else {
      $ret = $self->ua->get($key)->res;
    }
    if ($ret->is_success) {
      my $all = $ret->json;
      $self->stats->{network}{get}++;
      $self->chi->set($key, $all, '30d');
      return $all;
    } else {
      if ($ret->code == 403 && !$authorized) {
        return $self->get_with_cache($key, $force, 1);
      }
      croak $ret->message;
    }
  }
  return {};
}

=head2 C<discover_all>

  my $hashref = $disco->discover_all($force, $authenticate)

Return details about all Available Google APIs as provided by Google or in CHI Cache.
Does the fetching with C<get_with_cache>, and arguments are as above.

On Success: Returns HASHREF with keys discoveryVersion,items,kind
On Failure: Warns and returns empty hashref

SEE ALSO: available_APIs, list_of_available_google_api_ids

=cut

sub discover_key {'https://www.googleapis.com/discovery/v1/apis'}

sub discover_all {
  my $self = shift;
  $self->get_with_cache($self->discover_key, @_);
}


=head2 get_api_discovery_for_api_id

returns the cached version if avaiable in CHI otherwise retrieves discovery data via HTTP, stores in CHI cache and returns as
a Perl data structure.

    my $hashref = $self->get_api_discovery_for_api_id( 'gmail' );
    my $hashref = $self->get_api_discovery_for_api_id( 'gmail:v3' );
    my $hashref = $self->get_api_discovery_for_api_id( 'gmail:v3.users.list' );
    my $hashref = $self->get_api_discovery_for_api_id( { api=> 'gmail', version => 'v3' } );

NB: if deeper structure than the api_id is provided then only the head is used

so get_api_discovery_for_api_id( 'gmail' ) is the same as get_api_discovery_for_api_id( 'gmail.some.child.method' )

returns the api discovery specification structure ( cached by CHI ) for api id (eg 'gmail')

returns the discovery data as a hashref, an empty hashref on certain failing conditions or croaks on critical errors.

=cut

sub get_api_discovery_for_api_id {
  my ($self, $params) = @_;
  ## TODO: warn if user doesn't have the necessary scope .. no should stil be able to examine
  ## TODO: consolidate the http method calls to a single function - ie - discover_all - simplistic quick fix -  assume that if no param then endpoint is as per discover_all

  $params = { api => $params }
    if ref $params eq ''
    ; ## scalar parameter not hashref - so assume is intended to be $params->{api}

  ## trim any resource, method or version details in api id
  if ($params->{api} =~ /([^:]+):(v[^\.]+)/ixsm) {
    $params->{api}     = $1;
    $params->{version} = $2;
  }
  if ($params->{api} =~ /^(.*?)\./xsm) {
    $params->{api} = $1;
  }


  croak(
    "get_api_discovery_for_api_id called with api param undefined" . pp $params)
    unless defined $params->{api};
  $params->{version} = $self->latest_stable_version($params->{api})
    unless defined $params->{version};

  croak("get_api_discovery_for_api_id called with empty api param defined"
      . pp $params)
    if $params->{api} eq '';
  croak("get_api_discovery_for_api_id called with empty version param defined"
      . pp $params)
    if $params->{version} eq '';

  my $aapis = $self->available_APIs();


  my $api_verson_urls = {};
  for my $api (@{$aapis}) {
    for (my $i = 0; $i < scalar @{ $api->{versions} }; $i++) {
      $api_verson_urls->{ $api->{name} }{ $api->{versions}[$i] }
        = $api->{discoveryRestUrl}[$i];
    }
  }
  croak("Unable to determine discovery URI for any version of $params->{api}")
    unless defined $api_verson_urls->{ $params->{api} };
  croak(
    "Unable to determine discovery URI for $params->{api} $params->{version}")
    unless defined $api_verson_urls->{ $params->{api} }{ $params->{version} };
  my $api_discovery_uri
    = $api_verson_urls->{ $params->{api} }{ $params->{version} };

#carp "get_api_discovery_for_api_id requires data from  $api_discovery_uri" if $self->debug;
  if (my $dat = $self->chi->get($api_discovery_uri)
    ) ## clobbers some of the attempted thinking further on .. just return it for now if it's there
  {
    #carp pp $dat;
    $self->{stats}{cache}{get}++;
    return $dat;
  }

  if (my $expires_at = $self->chi->get_expires_at($api_discovery_uri)
    )    ## maybe this isn't th ebest way to check if get available.
  {
    carp "CHI '$api_discovery_uri' cached data with root = "
      . $self->chi->root_dir
      . "expires  in ", scalar($expires_at) - time(), " seconds\n"
      if $self->debug;

  #carp "Value = " . pp $self->chi->get( $api_discovery_uri ) if  $self->debug ;
    return $self->chi->get($api_discovery_uri);

  } else {
    carp "'$api_discovery_uri' not in cache - fetching it" if $self->debug;
    ## TODO: better handle failed response - if 403 then consider adding in the auth headers and trying again.
    #croak("Huh $api_discovery_uri");
    my $ret = $self->ua->validated_api_query($api_discovery_uri)
      ;    # || croak("Failed to retrieve $api_discovery_uri");;
    if ($ret->is_success) {
      my $dat = $ret->json
        || croak("failed to convert $api_discovery_uri return data in json");

      #carp("dat1 = " . pp $dat);
      $self->chi->set($api_discovery_uri, $dat, '30 days');
      $self->{stats}{network}{get}++;
      return $dat;

#my $ret_data = $self->chi->get( $api_discovery_uri );
#carp ("ret_data = " . pp $ret_data) unless ref($ret_data) eq 'HASH';
#return $ret_data;# if ref($ret_data) eq 'HASH';
#croak();
#$self->chi->remove( $api_discovery_uri ) unless eval '${^TAINT}'; ## if not hashref then assume is corrupt so delete it
    } else {
      ## TODO - why is this failing for certain resources ?? because the urls contain a '$' ? because they are now authenticated?
      carp("Fetching resource failed - $ret->message");    ## was croaking
      carp(pp $ret );
      return {};                                           #$ret;
    }
  }
  croak(
    "something went wrong in get_api_discovery_for_api_id key = '$api_discovery_uri' - try again to see if data corruption has been flushed for "
      . pp $params);

}



#TODO- is used in get_api_discover_for_api_id
#      is used in service_exists
#      is used in supported_as_text
#      is used in available_versions
#      is used in api_versions_urls
#      is used in list_of_available_google_api_ids
=head2 C<available_APIs>

Return arrayref of all available API's (services)

    {
      name => 'youtube',
      versions => [ 'v3' ]
      doclinks => [ ... ] ,
      discoveryRestUrl => [ ... ] ,
    },

Originally for printing list of supported API's in documentation ..
 

SEE ALSO: 
may be better/more flexible to use client->list_of_available_google_api_ids  
client->discover_all which is delegated to Client::Discovery->discover_all

=cut

#TODO- maybe cache this on disk too?
my $available;
sub _invalidate_available {
  $available = undef;
}

sub available_APIs {
  #cache this crunch
  return $available if $available;

  my ($self) = @_;
  my $d_all = $self->discover_all;
  croak 'no items in discovery data' unless defined $d_all->{items};

  my @keys = qw/name version documentationLink discoveryRestUrl/;
  my @relevant;
  for my $i (@{ $d_all->{items} }) {
    #grab only entries with the four keys we want, and strip other
    #keys
    next unless @keys == grep { exists $i->{$_} } @keys;
    push @relevant, { %{$i}{@keys} };
  };

  my $reduced = reduce {
    for my $key (qw/version documentationLink discoveryRestUrl/) {
      $a->{$b->{name}}->{$key} //= [];
      push @{$a->{$b->{name}}->{$key}}, $b->{$key};
    }
    $a;
  } {}, @relevant;

  $available = [
    map { {
      name             => $_,
      versions         => $reduced->{$_}{version},
      doclinks         => $reduced->{$_}{documentationLink},
      discoveryRestUrl => $reduced->{$_}{discoveryRestUrl}
    } } keys %$reduced
  ];
}

=head2 C<augment_with>

Allows you to augment the cached stored version of the discovery structure

    $augmented_document = $disco->augment_with({
      'version'   => 'v4',
      'preferred' => 1,
      'title'     => 'Google My Business API',
      'description' => 'The Google My Business API provides an interface for managing business location information on Google.',
      'id'                => 'mybusiness:v4',
      'kind'              => 'discovery#directoryItem',
      'documentationLink' => "https://developers.google.com/my-business/",
      'icons'             => {
        "x16" => "http://www.google.com/images/icons/product/search-16.gif",
        "x32" => "http://www.google.com/images/icons/product/search-32.gif"
      },
      'discoveryRestUrl' => 'https://developers.google.com/my-business/samples/mybusiness_google_rest_v4p2.json',
      'name' => 'mybusiness'
    });

This can also be used to overwrite the cached structure.

Can also be called as C<augment_discover_all_with_unlisted_experimental_api>, which is
being deprecated for being plain old too long.

=cut

sub augment_discover_all_with_unlisted_experimental_api {
  my ($self, $api_spec) = @_;
  carp <<DEPRECATION;
This lengthy function name will be removed soon.
Please use 'augment_with' instead.
DEPRECATION
  $self->augment_with($api_spec);
}

sub augment_with {
  my ($self, $api_spec) = @_;

  my $all = $self->discover_all();

  ## fail if any of the expected fields are not provided
  for my $field (
    qw/version title description id kind documentationLink
    discoveryRestUrl name/
  ) {
    if (not defined $api_spec->{$field}) {
      carp("required $field in provided api spec missing");
    }
  }

  push @{ $all->{items} }, $api_spec;
  $self->chi->set($self->discover_key, $all, '30d');
  $self->_invalidate_available;
  return $all
}


=head2 C<service_exists>

 Return 1 if Google Service API ID is described by Google API discovery. 
 Otherwise return 0

  print $d->service_exists('calendar');  # 1
  print $d->service_exists('someapi');  # 0

NB - Is case sensitive - all lower is required so $d->service_exists('Calendar') returns 0

=cut

sub service_exists {
  my ($self, $api) = @_;
  return 0 unless $api;
  my $apis_all = $self->available_APIs();
  return
    grep { $_->{name} eq $api }
    @$apis_all;    ## 1 iff an equality is found with keyed name
}

=head2 C<supported_as_text>

  No params.
  Returns list of supported APIs as string in human-readible format ( name, versions and doclinks )
 

=cut

sub supported_as_text {
  my ($self) = @_;
  my $ret = '';
  for my $api (@{ $self->available_APIs() }) {
    croak('doclinks key defined but is not the expected arrayref')
      unless ref $api->{doclinks} eq 'ARRAY';
    croak(
      'array of apis provided by available_APIs includes one without a defined name'
    ) unless defined $api->{name};

    my @clean_doclinks = grep { defined $_ }
      @{ $api->{doclinks} }
      ; ## was seeing undef in doclinks array - eg 'surveys'causing warnings in join

    ## unique doclinks using idiom from https://www.oreilly.com/library/view/perl-cookbook/1565922433/ch04s07.html
    my %seen     = ();
    my $doclinks = join(',', (grep { !$seen{$_}++ } @clean_doclinks))
      || '';    ## unique doclinks as string

    $ret
      .= $api->{name} . ' : '
      . join(',', @{ $api->{versions} }) . ' : '
      . $doclinks . "\n";
  }
  return $ret;
}

=head2 C<available_versions>

  Show available versions of particular API described by api id passed as parameter such as 'gmail'

  $d->available_versions('calendar');  # ['v3']
  $d->available_versions('youtubeAnalytics');  # ['v1','v1beta1']

  Returns arrayref

=cut

sub available_versions {
  my ($self, $api) = @_;
  return [] unless $api;
  my @api_target = grep { $_->{name} eq $api } @{ $self->available_APIs() };
  return [] if scalar(@api_target) == 0;
  return $api_target[0]->{versions};
}

=head2 C<latest_stable_version>

return latest stable verion of API

  $d->available_versions('calendar');  # ['v3']
  $d->latest_stable_version('calendar');  # 'v3'

  $d->available_versions('tagmanager');  # ['v1','v2']
  $d->latest_stable_version('tagmanager');  # ['v2']

  $d->available_versions('storage');  # ['v1','v1beta1', 'v1beta2']
  $d->latest_stable_version('storage');  # ['v1']

=cut

sub latest_stable_version {
  my ($self, $api) = @_;
  return '' unless $api;
  return '' unless $self->available_versions($api);
  return '' unless @{ $self->available_versions($api) } > 0;
  my $versions = $self->available_versions($api);    # arrayref
  if ($versions->[-1] =~ /beta/) {
    return $versions->[0];
  } else {
    return $versions->[-1];
  }
}


########################################################
sub api_version_urls {
  my ($self) = @_;
  ## transform structure to be keyed on api->versionRestUrl
  my $aapis           = $self->available_APIs();
  my $api_verson_urls = {};
  for my $api (@{$aapis}) {
    for (my $i = 0; $i < scalar @{ $api->{versions} }; $i++) {
      $api_verson_urls->{ $api->{name} }{ $api->{versions}[$i] }
        = $api->{discoveryRestUrl}[$i];
    }
  }
  return $api_verson_urls;
}
########################################################

=head2 C<extract_method_discovery_detail_from_api_spec>

    $agent->extract_method_discovery_detail_from_api_spec( $tree, $api_version )

returns a hashref representing the discovery specification for the method identified by $tree in dotted API format such as texttospeech.text.synthesize

returns an empty hashref if not found

=cut


########################################################
sub extract_method_discovery_detail_from_api_spec {
  my ($self, $tree, $api_version) = @_;
  ## where tree is the method in format from _extract_resource_methods_from_api_spec() like projects.models.versions.get
  ##   the root is the api id - further '.' sep levels represent resources until the tailing label that represents the method
  return {} unless defined $tree;

  my @nodes = split /\./smx, $tree;
  croak(
    "tree structure '$tree' must contain at least 2 nodes including api id, [list of hierarchical resources ] and method - not "
      . scalar(@nodes))
    unless scalar(@nodes) > 1;

  my $api_id = shift(@nodes);    ## api was head
  my $method = pop(@nodes);      ## method was tail

  ## split out version if is defined as part of $tree
  ## trim any resource, method or version details in api id
  if ($api_id =~ /([^:]+):([^\.]+)$/ixsm
    )    ## we have already isolated head from api tree children
  {
    $api_id      = $1;
    $api_version = $2;
  }

  ## handle incorrect api_id
  if ($self->service_exists($api_id) == 0) {
    carp("unable to confirm that '$api_id' is a valid Google API service id");
    return {};
  }

  $api_version = $self->latest_stable_version($api_id) unless $api_version;


  ## TODO: confirm that spec available for api version
  my $api_spec = $self->get_api_discovery_for_api_id(
    { api => $api_id, version => $api_version });


  ## we use the schemas to substitute into '$ref' keyed placeholders
  my $schemas = {};
  foreach my $schema_key (sort keys %{ $api_spec->{schemas} }) {
    $schemas->{$schema_key} = $api_spec->{'schemas'}{$schema_key};
  }

  ## recursive walk through the structure in _fix_ref
  ##  substitute the schema keys into the total spec to include
  ##  '$ref' values within the schema structures themselves
  ##  including within the schema spec structures (NB assumes no cyclic structures )
  ##   otherwise would could recursive chaos
  my $api_spec_fix = $self->_fix_ref($api_spec, $schemas)
    ;    ## first level ( '$ref' in the method params and return values etc )
  $api_spec = $self->_fix_ref($api_spec_fix, $schemas)
    ;    ## second level ( '$ref' in the interpolated schemas from first level )

  ## now extract all the methods (recursive )
  my $all_api_methods
    = $self->_extract_resource_methods_from_api_spec("$api_id:$api_version",
    $api_spec);

  #print dump $all_api_methods;exit;
  unless (defined $all_api_methods->{$tree}) {
    $all_api_methods
      = $self->_extract_resource_methods_from_api_spec($api_id, $api_spec);
  }
  if ($all_api_methods->{$tree}) {

    #add in the global parameters to the endpoint,
    #stored in the top level of the api_spec
    $all_api_methods->{$tree}{parameters} = {
      %{ $all_api_methods->{$tree}{parameters} },
      %{ $api_spec->{parameters} }
    };
    return $all_api_methods->{$tree};
  }

  carp(
    "Unable to find method detail for '$tree' within Google Discovery Spec for $api_id version $api_version"
  ) if $self->debug;
  return {};
}
########################################################

########################################################
sub _extract_resource_methods_from_api_spec {
  my ($self, $tree, $api_spec, $ret) = @_;
  $ret = {} unless defined $ret;
  croak("ret not a hash - $tree, $api_spec, $ret") unless ref($ret) eq 'HASH';

  if (defined $api_spec->{methods} && ref($api_spec->{methods}) eq 'HASH') {
    foreach my $method (keys %{ $api_spec->{methods} }) {
      $ret->{"$tree.$method"} = $api_spec->{methods}{$method}
        if ref($api_spec->{methods}{$method}) eq 'HASH';
    }
  }
  if (defined $api_spec->{resources}) {
    foreach my $resource (keys %{ $api_spec->{resources} }) {
      ## NB - recursive traversal down tree of api_spec resources
      $self->_extract_resource_methods_from_api_spec("$tree.$resource",
        $api_spec->{resources}{$resource}, $ret);
    }
  }
  return $ret;
}
########################################################

#=head2 C<fix_ref>
#
#This sub walks through the structure and replaces any hashes keyed with '$ref' with
#the value defined in $schemas->{ <value of keyed $ref> }
#
#eg
# ->{'response'}{'$ref'}{'Buckets'}
# is replaced with
# ->{response}{ $schemas->{Buckets} }
#
# It assumes that the schemas have been extracted from the original discover for the API
# and is typically applued to the method ( api endpoint ) to provide a fully descriptive
# structure without external references.
#
#=cut

########################################################
sub _fix_ref {
  my ($self, $node, $schemas) = @_;
  my $ret = undef;
  my $r   = ref($node);


  if ($r eq 'ARRAY') {
    $ret = [];
    foreach my $el (@$node) {
      push @$ret, $self->_fix_ref($el, $schemas);
    }
  } elsif ($r eq 'HASH') {
    $ret = {};
    foreach my $key (keys %$node) {
      if ($key eq '$ref') {

        #say $node->{'$ref'};
        $ret = $schemas->{ $node->{'$ref'} };
      } else {
        $ret->{$key} = $self->_fix_ref($node->{$key}, $schemas);
      }
    }
  } else {
    $ret = $node;
  }

  return $ret;
}
########################################################


=head2 C<methods_available_for_google_api_id>

Returns a hashref keyed on the Google service API Endpoint in dotted format.
The hashed content contains a structure
representing the corresponding discovery specification for that method ( API Endpoint )

    methods_available_for_google_api_id('gmail.users.settings.delegates.get');

    methods_available_for_google_api_id('gmail.users.settings.delegates.get', 'v1');


=cut

#TODO: consider ? refactor to allow parameters either as a single api id such as 'gmail'
#      as well as the currently accepted  hash keyed on the api and version
#
#SEE ALSO:
#  The following methods are delegated through to Client::Discovery - see perldoc WebService::Client::Discovery for detils
#
#  get_method_meta
#  discover_all
#  extract_method_discovery_detail_from_api_spec
#  get_api_discovery_for_api_id

########################################################
## TODO: consider renaming ?
sub methods_available_for_google_api_id {
  my ($self, $api_id, $version) = @_;

  $version = $self->latest_stable_version($api_id) unless $version;
  ## TODO: confirm that spec available for api version
  my $api_spec = $self->get_api_discovery_for_api_id(
    { api => $api_id, version => $version });
  my $methods
    = $self->_extract_resource_methods_from_api_spec($api_id, $api_spec);
  return $methods;
}
########################################################


=head2 C<list_of_available_google_api_ids>

Returns an array list of all the available API's described in the API Discovery Resource
that is either fetched or cached in CHI locally for 30 days.

    my $r = $agent->list_of_available_google_api_ids();
    print "List of API Services ( comma separated): $r\n";

    my @list = $agent->list_of_available_google_api_ids();

=cut

########################################################
## returns a list of all available API Services
sub list_of_available_google_api_ids {
  my ($self)   = @_;
  my $aapis    = $self->available_APIs();      ## array of hashes
  my @api_list = map { $_->{name} } @$aapis;
  return
    wantarray
    ? @api_list
    : join(',', @api_list)
    ;    ## allows to be called in either list or scalar context
         #return @api_list;

}
########################################################


1;

## TODO - CODE REVIEW
## get_expires_at .. does this do what is expected ? - what if has expired and so get fails - will this still return a value?
