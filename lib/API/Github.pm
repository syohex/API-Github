# ABSTRACT: Perl 5 API wrapper for Github
package API::Github;

use API::Github::Class;

extends 'API::Github::Client';

use Carp ();
use Scalar::Util ();

# VERSION

has identifier => (
    is       => 'rw',
    isa      => STRING,
    default  => 'API::Github (Perl)',
);

has username => (
    is       => 'rw',
    isa      => STRING,
    required => 1,
);

has token => (
    is       => 'rw',
    isa      => STRING,
    required => 1,
);

has version => (
    is       => 'rw',
    isa      => INTEGER,
    default  => 3,
);

method AUTOLOAD () {
    my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
    Carp::croak "Undefined subroutine &${package}::$method called"
        unless Scalar::Util::blessed $self && $self->isa(__PACKAGE__);

    # return new resource instance dynamically
    return $self->resource($method, @_);
}

method BUILD () {
    my $identifier = $self->identifier;
    my $username   = $self->username;
    my $token      = $self->token;
    my $version    = $self->version;

    my $userinfo   = "$username:$token";
    my $agent      = $self->user_agent;
    my $url        = $self->url;

    $agent->transactor->name($identifier);

    # $url->path("/v$version");
    $url->userinfo($userinfo);

    return $self;
}

method PREPARE ($ua, $tx, %args) {
    my $headers = $tx->req->headers;
    my $url     = $tx->req->url;

    # default headers
    $headers->header('Content-Type' => 'application/json');
}

method action ($method, %args) {
    $method = uc($method || 'get');

    # execute transaction and return response
    return $self->$method(%args);
}

method create (%args) {
    # execute transaction and return response
    return $self->POST(%args);
}

method delete (%args) {
    # execute transaction and return response
    return $self->DELETE(%args);
}

method fetch (%args) {
    # execute transaction and return response
    return $self->GET(%args);
}

method resource (@segments) {
    # build new resource instance
    my $instance = __PACKAGE__->new(
        debug      => $self->debug,
        fatal      => $self->fatal,
        retries    => $self->retries,
        timeout    => $self->timeout,
        user_agent => $self->user_agent,
        identifier => $self->identifier,
        username   => $self->username,
        token      => $self->token,
        version    => $self->version,
    );

    # resource locator
    my $url = $instance->url;

    # modify resource locator if possible
    $url->path(join '/', $self->url->path, @segments);

    # return resource instance
    return $instance;
}

method update (%args) {
    # execute transaction and return response
    return $self->PUT(%args);
}

1;

=encoding utf8

=head1 SYNOPSIS

    use API::Github;

    my $github = API::Github->new(
        username   => 'USERNAME',
        token      => 'TOKEN',
        identifier => 'APPLICATION (yourname@example.com)',
    );

    my $user = $github->users('h@x0r');
    my $results = $user->fetch;

    # after some introspection

    $user->update(%data);

    # or, e.g.

    my $repo = $github->repos('h@x0r' => 'omnibus');
    my $results = $repo->pulls;

=head1 DESCRIPTION

This distribution provides an object-oriented thin-client library for
interacting with the Github (L<http://github.com>) API. For usage and
documentation information visit L<https://developer.github.com/v3/>.

=cut

=head1 THIN CLIENT

A thin-client library is advantageous as it has complete coverage and can
easily adapt to changes in the API with minimal effort. As a thin-client
library, this module does not map specific HTTP requests to specific routines
nor does it provide parameter validation, pagination, or other conventions
found in typical API client implementations, instead, it simply provides a
simple and consistent mechanism for dynamically generating HTTP requests.
Additionally, this module has support for debugging and retrying API calls as
well as throwing exceptions when 4xx and 5xx server response codes are
received.

=cut

=head2 Building

    my $user = $github->users('h@x0r');
    my $repos = $user->repos;

    $repos->action; # GET /users/h@x0r/repos
    $repos->action('head'); # HEAD /users/h@x0r/repos

Building up an HTTP request object is extremely easy, simply call method names
which correspond to the API's path segments in the resource you wish to execute
a request against. This module uses autoloading and returns a new instance with
each method call. The following is the equivalent:

    my $user = $github->resource(users => 'h@x0r');
    my $repos = $user->resource('repos');

    # or

    my $repos = $github->resource('users', 'h@x0r', 'repos');

    # then

    $repos->action('put', %args); # PUT /users/h@x0r/repos

Because each call returns a new API instance configured with a resource locator
based on the supplied parameters, reuse and request isolation are made simple,
i.e., you will only need to configure the client once in your application.

=head2 Fetching

    my $users = $github->users;

    $users->fetch(
        query => {
            # query-string parameters
        },
    );

    # equivalent to

    $github->resource('users')->action(
        get => ( query => { ... } )
    );

This example illustrates how you might fetch an API resource.

=head2 Creating

    my $users = $github->users;

    $users->create(
        data => {
            # content-body parameters
        },
        query => {
            # query-string parameters
        },
    );

    # or

    my $users = $github->users->create(...);

    # equivalent to

    $github->resource('users')->action(
        post => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might create a new API resource.

=head2 Updating

    my $users = $github->users;
    my $user  = $users->resource('h@x0r');

    $user->update(
        data => {
            # content-body parameters
        },
        query => {
            # query-string parameters
        },
    );

    # or

    my $user = $github->users('h@x0r');

    $user->update(...);

    # equivalent to

    $github->resource('users')->action(
        put => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might update an new API resource.

=head2 Deleting

    my $users = $github->users;
    my $user  = $users->resource('h@x0r');

    $user->delete(
        data => {
            # content-body parameters
        },
        query => {
            # query-string parameters
        },
    );

    # or

    my $user = $github->users('h@x0r');

    $user->delete(...);

    # equivalent to

    $github->resource('users')->action(
        delete => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might delete an API resource.

=cut

=head2 Transacting

    my $user = $github->resource('users', 'h@x0r');

    my ($results, $transaction) = $user->fetch(...);

This example illustrates how you can access the transaction object used to
submit the HTTP request.

=cut

=param identifier

    $github->identifier;
    $github->identifier('IDENTIFIER');

The identifier parameter should be set to a string that identifies your app.

=cut

=param token

    $github->token;
    $github->token('TOKEN');

The token parameter should be set to the API user's personal access token.

=cut

=param username

    $github->username;
    $github->username('USERNAME');

The username parameter should be set to the API user's username.

=cut

=attr debug

    $github->debug;
    $github->debug(1);

The debug attribute if true prints HTTP requests and responses to standard out.

=cut

=attr fatal

    $github->fatal;
    $github->fatal(1);

The fatal attribute if true promotes 4xx and 5xx server response codes to
exceptions, a L<API::Github::Exception> object.

=cut

=attr retries

    $github->retries;
    $github->retries(10);

The retries attribute determines how many times an HTTP request should be
retried if a 4xx or 5xx response is received. This attribute defaults to 1.

=cut

=attr timeout

    $github->timeout;
    $github->timeout(5);

The timeout attribute determines how long an HTTP connection should be kept
alive. This attribute defaults to 10.

=cut

=attr url

    $github->url;
    $github->url(Mojo::URL->new('https://api.github.com'));

The url attribute set the base/pre-configured URL object that will be used in
all HTTP requests. This attribute expects a L<Mojo::URL> object.

=cut

=attr user_agent

    $github->user_agent;
    $github->user_agent(Mojo::UserAgent->new);

The user_agent attribute set the pre-configured UserAgent object that will be
used in all HTTP requests. This attribute expects a L<Mojo::UserAgent> object.

=cut

=method action

    my $result = $github->action($verb, %args);

    # e.g.

    $github->action('head', %args);   # HEAD request
    $github->action('optons', %args); # OPTIONS request
    $github->action('patch', %args);  # PATCH request


The action method issues a request to the API resource represented by the
object. The first parameter will be used as the HTTP request method. The
arguments, expected to be a list of key/value pairs, will be included in the
request if the key is either C<data> or C<query>.

=cut

=method create

    my $results = $github->create(%args);

    # or

    $github->POST(%args);

The create method issues a C<POST> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=method delete

    my $results = $github->delete(%args);

    # or

    $github->DELETE(%args);

The delete method issues a C<DELETE> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=method fetch

    my $results = $github->fetch(%args);

    # or

    $github->GET(%args);

The fetch method issues a C<GET> request to the API resource represented by the
object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=method update

    my $results = $github->update(%args);

    # or

    $github->PUT(%args);

The update method issues a C<PUT> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=resource emojis

    $github->emojis;

The emojis method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/emojis/>.

=cut

=resource events

    $github->events;

The events method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/activity/events/>.

=cut

=resource feeds

    $github->feeds;

The feeds method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/activity/feeds/>.

=cut

=resource gists

    $github->gists;

The gists method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/gists/>.

=cut

=resource gitignore

    $github->gitignore;

The gitignore method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/gitignore/>.

=cut

=resource issues

    $github->issues;

The issues method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/issues/>.

=cut

=resource licenses

    $github->licenses;

The licenses method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/licenses/>.

=cut

=resource markdown

    $github->markdown;

The markdown method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/markdown/>.

=cut

=resource meta

    $github->meta;

The meta method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/meta/>.

=cut

=resource notifications

    $github->notifications;

The notifications method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/activity/notifications/>.

=cut

=resource orgs

    $github->orgs;

The orgs method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/orgs/>.

=cut

=resource rate_limit

    $github->rate_limit;

The rate_limit method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/rate_limit/>.

=cut

=resource repos

    $github->repos;

The repos method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/repos/>.

=cut

=resource search

    $github->search;

The search method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/search/>.

=cut

=resource users

    $github->users;

The users method returns a new instance representative of the API
resource requested. This method accepts a list of path segments which will be
used in the HTTP request. The following documentation can be used to find more
information. L<https://developer.github.com/v3/users/>.

=cut

