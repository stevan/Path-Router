#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Path::Router;

{
    my $router = Path::Router->new;
    $router->add_route('1/0');
    my $match = $router->match('1/0');
    ok($match);
    is_deeply($match->route->components, [1, 0]);
}

{
    my $router = Path::Router->new;
    $router->add_route('0/1');
    my $match = $router->match('0/1');
    ok($match);
    is_deeply($match->route->components, [0, 1]);
}

done_testing;
