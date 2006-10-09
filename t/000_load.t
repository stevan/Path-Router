#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;

BEGIN {
    use_ok('Path::Router');
    use_ok('Path::Router::Route');    
    use_ok('Path::Router::Shell');        
    use_ok('Test::Path::Router');        
}