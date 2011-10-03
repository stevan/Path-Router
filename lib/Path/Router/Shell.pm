package Path::Router::Shell;
use Moose;
# ABSTRACT: An interactive shell for testing router configurations

use Term::ReadLine;
use Data::Dumper;

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

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 SYNOPSIS

  #!/usr/bin/perl

  use strict;
  use warnings;

  use My::App::Router;
  use Path::Router::Shell;

  Path::Router::Shell->new(router => My::App::Router->new)->shell;

=head1 DESCRIPTION

This is a tool for helping test the routing in your applications, so
you simply write a small script like showing in the SYNOPSIS and then
you can use it to test new routes or debug routing issues, etc etc etc.

=head1 METHODS

=over 4

=item B<new (router => $router)>

=item B<router>

=item B<shell>

=item B<meta>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
