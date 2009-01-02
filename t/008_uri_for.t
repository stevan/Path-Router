#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Path::Router;
use Path::Router;

my $router = Path::Router->new;

$router->add_route('/' => (
    defaults => {
        controller => 'root',
        action     => 'index',
    }
));

mapping_is(
    $router,
    {
        controller => 'root',
        action     => 'index',
    },
    '',
    'return "" for /',
);

mapping_is(
    $router,
    {
        controller => 'root',
        action     => 'bogus',
    },
    undef,
    'return undef for bogus mapping',
);
