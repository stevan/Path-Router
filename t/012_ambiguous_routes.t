#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Path::Router;

{
    my $router = Path::Router->new;

    $router->add_route('/foo' =>
        defaults => { a => 'b', c => 'd', e => 'f' }
    );
    $router->add_route('/bar' =>
        defaults => { a => 'b', c => 'd' }
    );

    is($router->uri_for(a => 'b'), 'bar');
}

{
    my $router = Path::Router->new;

    $router->add_route('/bar' =>
        defaults => { a => 'b', c => 'd' }
    );
    $router->add_route('/foo' =>
        defaults => { a => 'b', c => 'd', e => 'f' }
    );

    is($router->uri_for(a => 'b'), 'bar');
}

{
    my $router = Path::Router->new;

    $router->add_route('/foo' =>
        defaults => { a => 'b', c => 'd', e => 'f' }
    );
    $router->add_route('/bar' =>
        defaults => { a => 'b', c => 'd', g => 'h' }
    );

    like(
        exception { $router->uri_for(a => 'b', c => 'd') },
        qr{^\QAmbiguous path descriptor (specified keys a, c): could match paths /bar, /foo},
        "error when it's actually ambiguous"
    );
}

{
    my $router = Path::Router->new;

    $router->add_route('/foo/:bar' => (defaults => { id => 1 }));
    $router->add_route('/foo/bar'  => (defaults => { id => 2 }));

    my $match = $router->match('/foo/bar');
    is($match->mapping->{id}, 2);
}

{
    my $router = Path::Router->new;

    $router->add_route('/foo/bar'  => (defaults => { id => 2 }));
    $router->add_route('/foo/:bar' => (defaults => { id => 1 }));

    my $match = $router->match('/foo/bar');
    is($match->mapping->{id}, 2);
}

done_testing;
