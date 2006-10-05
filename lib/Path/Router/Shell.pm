
package Path::Router::Shell;
use Moose;

use Term::Readline;
use Data::Dumper;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

has 'router' => (
    is       => 'ro',
    isa      => 'Path::Router',
    required => 1,
);

sub shell {
    my $self = shift;
    
    my $term = Term::ReadLine->new(__PACKAGE__);
    my $OUT = $term->OUT || \*STDOUT;

    while ( defined ($_ = $term->readline("> ")) ) {
        chomp;
        return if /[qQ]/;
        my $map = $self->router->match($_);
        if ($map) {        
            print $OUT Dumper $map;
            print $OUT "Round-trip URI is : " . $self->router->uri_for(%$map),
        }
        else {
            print $OUT "No match for $_\n";
        }
        $term->addhistory($_) if /\S/;
    }
}

no Moose; 1

__END__

=pod

=head1 NAME

Path::Router::Shell - An interactive shell for testing router configurations

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new (router => $router)>

=item B<router>

=item B<shell>

=item B<meta>

=back

=head1 AUTHORS

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut