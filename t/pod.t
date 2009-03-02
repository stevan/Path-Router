#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;

plan skip_all => "set env var RELEASE_TESTING to test POD"
  unless $ENV{RELEASE_TESTING};

all_pod_files_ok();
