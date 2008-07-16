#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
    use_ok('Path::Router');
    use_ok('Path::Router::Route');         
    use_ok('Path::Router::Route::Match');     
    use_ok('Path::Router::Shell');         
    use_ok('Path::Router::Types');             
    use_ok('Test::Path::Router');       
}