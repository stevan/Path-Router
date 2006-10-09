
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

=head1 DESCRIPTION

=head1 EXPORTED FUNCTIONS

=over 4

=item B<routes_ok>

=back

=head1 AUTHORS

Stevan Little E<lt>stevan.little@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Stevan Little

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut