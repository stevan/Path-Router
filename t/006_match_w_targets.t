#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Path::Router;

BEGIN {
    use_ok('Path::Router');
}

my $INDEX     = bless {} => 'Blog::Index';
my $SHOW_DATE = bless {} => 'Blog::ShowDate';
my $GENERAL   = bless {} => 'Blog::Controller';

my $router = Path::Router->new;
isa_ok($router, 'Path::Router');

# create some routes

$router->add_route('blog' => (
    defaults       => {
        controller => 'blog',
        action     => 'index',
    },
    target => $INDEX,
));

$router->add_route('blog/:year/:month/:day' => (
    defaults       => {
        controller => 'blog',
        action     => 'show_date',
    },
    validations => {
        year    => qr/\d{4}/,
        month   => qr/\d{1,2}/,
        day     => qr/\d{1,2}/,
    },
    target => $SHOW_DATE,
));

$router->add_route('blog/:action/:id' => (
    defaults       => {
        controller => 'blog',
    },
    validations => {
        action  => qr/\D+/,
        id      => qr/\d+/
    },
    target => $GENERAL
));

{
    my $match = $router->match('/blog/');
    isa_ok($match, 'Path::Router::Route::Match');

    is($match->route->target, $INDEX, '... got the right target');
}
{
    my $match = $router->match('/blog/2006/12/1');
    isa_ok($match, 'Path::Router::Route::Match');

    is($match->route->target, $SHOW_DATE, '... got the right target');
}
{
    my $match = $router->match('/blog/show/5');
    isa_ok($match, 'Path::Router::Route::Match');

    is($match->route->target, $GENERAL, '... got the right target');
}

1;
