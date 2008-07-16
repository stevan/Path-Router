#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Path::Router;

use Moose::Util::TypeConstraints;

BEGIN {
    use_ok('Path::Router');
}

subtype 'NumericMonth'
    => as 'Int'
    => where { $_ <= 12 };

my $router = Path::Router->new;
isa_ok($router, 'Path::Router');

can_ok($router, 'add_route');
can_ok($router, 'match');
can_ok($router, 'uri_for');

# create some routes

$router->add_route('blog' => (
    defaults       => {
        controller => 'blog',
        action     => 'index',
    }
));

$router->add_route('blog/:year/:month/:day' => (
    defaults       => {
        controller => 'blog',
        action     => 'show_date',      
    }, 
    validations => {
        year    => qr/\d{4}/,
        month   => 'NumericMonth',
        day     => subtype('Int' => where { $_ <= 31 }),    
    }
));

$router->add_route('blog/:action/:id' => (
    defaults       => {
        controller => 'blog',
    }, 
    validations => {
        action  => qr/\D+/,        
        id      => 'Int'    
    }
));

# create some tests

routes_ok($router, {
    # blog
    'blog' => {
        controller => 'blog',
        action     => 'index',
    },    
    # blog/:year/:month/:day
    'blog/2006/12/5' => {
        controller => 'blog',
        action     => 'show_date',
        year       => 2006,
        month      => 12,
        day        => 5,        
    },
    # blog/:year/:month/:day
    'blog/1920/12/10' => {
        controller => 'blog',
        action     => 'show_date',
        year       => 1920,
        month      => 12,
        day        => 10,        
    },    
    # blog/:action/:id
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
    'blog/some_crazy_long_winded_action_name/12356789101112131151' => {
        controller => 'blog',
        action     => 'some_crazy_long_winded_action_name',
        id         => '12356789101112131151',
    },    
    'blog/delete/5' => {
        controller => 'blog',
        action     => 'delete',
        id         => 5,
    },        
},
"... our routes are solid");


1;




