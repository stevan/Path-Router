#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;

use Data::Dumper;

BEGIN {
    use_ok('Path::Router');
}

my $router = Path::Router->new;
isa_ok($router, 'Path::Router');
isa_ok($router, 'Moose::Object');

can_ok($router, 'add_route');
can_ok($router, 'match');
can_ok($router, 'uri_for');

# create some routes

$router->add_route('blog/' => {
    controller => 'blog',
    action     => 'index',
});
$router->add_route('blog/:year/:month/:day' => {
    controller => 'blog',
    action     => 'show_date',
    year       => qr/\d\d\d\d/,
    month      => qr/\d\d?/,
    day        => qr/\d\d?/,        
});
$router->add_route(':controller/match/:id' => {
    action => 'matching'
});
$router->add_route('blog/:controller/:action/:id' => {
    base => 'blog',
});
$router->add_route(':controller/:action/:id' => {
    id => qr/\d+/
});

# create some tests

my %tests = (
    # :controller/:action/:id
    'blog/edit/5' => {
        controller => 'blog',
        action     => 'edit',
        id         => 5
    },
    'blog/show/123' => {
        controller => 'blog',
        action     => 'show',
        id         => 123
    }, 
    # :controller/match/:id   
    'baz/match/bar' => {
        controller => 'baz',
        action     => 'matching',
        id         => 'bar'
    }, 
    # :controller/match/:id    
    'blog/match/3' => {
        controller => 'blog',
        action     => 'matching',
        id         => 3        
    },
    # blog/:year/:month/:day
    'blog/2006/20/5' => {
        controller => 'blog',
        action     => 'show_date',
        year       => 2006,
        month      => 20,
        day        => 5,        
    },
    # blog/:year/:month/:day
    'blog/1920/1/50' => {
        controller => 'blog',
        action     => 'show_date',
        year       => 1920,
        month      => 1,
        day        => 50,        
    },    
    # blog/
    'blog' => {
        controller => 'blog',
        action     => 'index',
    },  
    # blog/:controller/:action/:id
    'blog/article/delete/5' => {
        base       => 'blog',
        controller => 'article',
        action     => 'delete',
        id         => 5,
    }, 
    'blog/index/build/2005106' => {
        base       => 'blog',
        controller => 'index',
        action     => 'build',
        id         => 2005106,
    },         
);

# test the roundtrip

foreach my $path (keys %tests) {
    # the path generated from the hash
    # is the same as the path supplied
    is(
        $path, 
        $router->uri_for(%{$tests{$path}}), 
        '... round-tripping the light fantasitc'
    );
    # the path supplied produces the
    # same match as the hash supplied 
    is_deeply(
        $router->match($path),
        $tests{$path},
        '... dont call it a comeback, I been here for years'
    );    
}

1;




