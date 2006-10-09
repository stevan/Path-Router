
package Test::Path::Router;

use strict;
use warnings;

use Test::Builder ();
use Test::Deep    ();
use Data::Dumper  ();
use Sub::Exporter;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

Sub::Exporter::setup_exporter({ 
    exports => [ qw(routes_ok) ],
    groups  => { default => [ qw(routes_ok) ] }
});

our $Test = Test::Builder->new;

sub routes_ok {
    my ($router, $routes, $message) = @_;
    my ($passed, $reason);
    foreach my $path (keys %$routes) {
        my $mapping = $routes->{$path};

        my $generated_path = $router->uri_for(%{$mapping});

        # the path generated from the hash
        # is the same as the path supplied        
        if ($path ne $generated_path) {
            $Test->ok(0, $message);             
            $Test->diag("... paths do not match\n" . 
                        "   got:      '" . $path . "'\n" .
                        "   expected: '" . $generated_path . "'");                       
            return;
        }
        
        my $generated_mapping = $router->match($path);
        
        # the path supplied produces the
        # same match as the hash supplied 
        
        unless (Test::Deep::eq_deeply($generated_mapping, $mapping)) {
            $Test->ok(0, $message);             
            $Test->diag("... mappings do not match for '$path'\n" . 
                        "   got:      '" . Data::Dumper::Dumper($generated_mapping) . "'\n" .
                        "   expected: '" . Data::Dumper::Dumper($mapping) . "'");                       
            return;            
        }    
    }   
    $Test->ok(1, $message);
}

1;

__END__

=pod

=head1 NAME

Test::Path::Router - A testing module for testing routes

=head1 SYNOPSIS

  use Test::More plan => 1;
  use Test::Path::Router;

  my $router = Path::Router->new;
  
  # ... define some routes
  
  routes_ok($router, { 
      'admin' => {
          controller => 'admin',
          action     => 'index',
      },
      'admin/add_user' => {
          controller => 'admin',
          action     => 'add_user',
      },
      'admin/edit_user/5' => {
          controller => 'admin',
          action     => 'edit_user',
          user_id    => 5,
      }    
  },
  "... our routes are valid");

=head1 DESCRIPTION

This module helps in testing out your path routes, to make sure 
they are valid.

=head1 EXPORTED FUNCTIONS

=over 4

=item B<routes_ok ($router, \%test_routes, ?$message)>

This test function will accept a set of C<%test_routes> which 
will get checked against your C<$router> instance. This will 
check to be sure that all paths in C<%test_routes> procude 
the expected mappings, and that all mappings also produce the 
expected paths. It basically assures you that your paths 
are roundtrippable, so that you can be confident in them.

=back

=head1 AUTHORS

Stevan Little E<lt>stevan.little@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Stevan Little

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut