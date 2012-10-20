#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Path::Router;

for my $inline (0, 1) {
    for my $path ('0/1', '1/0') {
        my $router = Path::Router->new(inline => $inline);
        $router->add_route($path);
        my $match = $router->match($path);
        ok($match);
        is_deeply($match->route->components, [split '/', $path]);
    }
}

done_testing;
