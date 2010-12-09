#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Path::Router;

BEGIN {
    use_ok('Path::Router');
}

my $router = Path::Router->new;
isa_ok($router, 'Path::Router');

# create some routes

$router->add_route('person/create' => (
    defaults   => {
        relation => 'create',
        method   => 'PUT',
    }
));

$router->add_route('person/:id/read' => (
    defaults   => {
        relation => 'self',
        method   => 'GET',
    }
));

$router->add_route('person/:id/update' => (
    defaults   => {
        relation => 'self',
        method   => 'POST',
    }
));

$router->add_route('person/:id/delete' => (
    defaults   => {
        relation => 'self',
        method   => 'DELETE',
    }
));

# run it through some tests

routes_ok($router, {
	'person/create' => {
        relation => 'create',
        method   => 'PUT',
	},
	'person/1/read' => {
        relation => 'self',
        method   => 'GET',
        id       => 1
	},
	'person/1/update' => {
        relation => 'self',
        method   => 'POST',
        id       => 1
	},
	'person/1/delete' => {
        relation => 'self',
        method   => 'DELETE',
        id       => 1
	},
},
"... our routes are solid");

1;




