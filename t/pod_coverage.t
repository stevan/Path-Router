#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

plan skip_all => "set env var RELEASE_TESTING to test POD"
  unless $ENV{RELEASE_TESTING};

all_pod_coverage_ok();
