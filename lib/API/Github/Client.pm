# Github Client Super Class
package API::Github::Client;

use API::Github::Class;
use API::Github::Exception;

use Mojo::UserAgent;
use Mojo::URL;

# VERSION

has debug => (
    is       => 'rw',
    isa      => INTEGER,
    default  => 0,
);

has fatal => (
    is       => 'rw',
    isa      => INTEGER,
    default  => 0,
);

has retries => (
    is       => 'rw',
    isa      => INTEGER,
    default  => 0,
);

has timeout => (
    is       => 'rw',
    isa      => INTEGER,
    default  => 10,
);

has url => (
    is       => 'ro',
    isa      => URL,
    default  => fun { Mojo::URL->new("https://api.github.com") },
);

has user_agent => (
    is       => 'ro',
    isa      => USERAGENT,
    default  => fun { Mojo::UserAgent->new },
);

my @methods = qw(
    DELETE
    GET
    HEAD
    OPTIONS
    PATCH
    POST
    PUT
);

around [@methods] => fun ($orig, $self, %args) {
    my $retries = $self->retries;
    my $ua      = $self->user_agent;

    # client timeouts
    $ua->max_redirects(0);
    $ua->connect_timeout($self->timeout);
    $ua->request_timeout($self->timeout);

    # request defaults
    $ua->on(start => fun ($ua, $tx) {
        $self->PREPARE($ua, $tx, %args);
    });

    # retry entry point
    RETRY:

    # execute transaction
    my $tx  = $self->$orig(%args);
    my $ok  = $tx->res->code !~ /(4|5)\d\d/;

    # fetch transaction objects
    my $req = $tx->req;
    my $res = $tx->res;

    # attempt logging where applicable
    if ($self->debug) {
        my $reqstr = $req->to_string;
        my $resstr = $res->to_string;

        $reqstr =~ s/\s*$/\n\n\n/;
        $resstr =~ s/\s*$/\n\n\n/;

        print STDOUT $reqstr;
        print STDOUT $resstr;
    }

    # retry transaction where applicable
    goto RETRY if $retries-- > 0 and not $ok;

    # throw exception if fatal is enabled
    if ($self->fatal and not $ok) {
        API::Github::Exception->throw(
            res    => $res,
            code   => $res->code,
            method => $req->method,
            url    => $req->url->to_string,
        );
    }

    # return JSON
    return $res->json;
};

method DELETE (STRING :$path = '', HASH :$data = {}, HASH :$query = {}) {
    my $ua  = $self->user_agent;
    my $url = $self->url->clone;

    $url->path(join '/', $url->path, $path) if $path;
    $url->query($url->query->merge(%$query)) if keys %$query;

    return $ua->delete($url, ({}, keys(%$data) ? (json => $data) : ()));
}

fun DESTROY {
    ; # Protect subclasses using AUTOLOAD
}

method GET (STRING :$path = '', HASH :$data = {}, HASH :$query = {}) {
    my $ua  = $self->user_agent;
    my $url = $self->url->clone;

    $url->path(join '/', $url->path, $path) if $path;
    $url->query($url->query->merge(%$query)) if keys %$query;

    return $ua->get($url, ({}, keys(%$data) ? (json => $data) : ()));
}

method HEAD (STRING :$path = '', HASH :$data = {}, HASH :$query = {}) {
    my $url = $self->url->clone;
    my $ua  = $self->user_agent;

    $url->path(join '/', $url->path, $path) if $path;
    $url->query($url->query->merge(%$query)) if keys %$query;

    return $ua->head($url, ({}, keys(%$data) ? (json => $data) : ()));
}

method OPTIONS (STRING :$path = '', HASH :$data = {}, HASH :$query = {}) {
    my $url = $self->url->clone;
    my $ua  = $self->user_agent;

    $url->path(join '/', $url->path, $path) if $path;
    $url->query($url->query->merge(%$query)) if keys %$query;

    return $ua->options($url, ({}, keys(%$data) ? (json => $data) : ()));
}

method PATCH (STRING :$path = '', HASH :$data = {}, HASH :$query = {}) {
    my $url = $self->url->clone;
    my $ua  = $self->user_agent;

    $url->path(join '/', $url->path, $path) if $path;
    $url->query($url->query->merge(%$query)) if keys %$query;

    return $ua->patch($url, ({}, keys(%$data) ? (json => $data) : ()));
}

method POST (STRING :$path = '', HASH :$data = {}, HASH :$query = {}) {
    my $url = $self->url->clone;
    my $ua  = $self->user_agent;

    $url->path(join '/', $url->path, $path) if $path;
    $url->query($url->query->merge(%$query)) if keys %$query;

    return $ua->post($url, ({}, keys(%$data) ? (json => $data) : ()));
}

method PUT (STRING :$path = '', HASH :$data = {}, HASH :$query = {}) {
    my $url = $self->url->clone;
    my $ua  = $self->user_agent;

    $url->path(join '/', $url->path, $path) if $path;
    $url->query($url->query->merge(%$query)) if keys %$query;

    return $ua->put($url, ({}, keys(%$data) ? (json => $data) : ()));
}

1;
