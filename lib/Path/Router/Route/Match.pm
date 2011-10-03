package Path::Router::Route::Match;
use Moose;
# ABSTRACT: The result of a Path::Router match

has 'path'    => (is => 'ro', isa => 'Str',     required => 1);
has 'mapping' => (is => 'ro', isa => 'HashRef', required => 1);

has 'route'   => (
    is       => 'ro',
    isa      => 'Path::Router::Route',
    required => 1,
    handles  => [qw[target]]
);

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 DESCRIPTION

This is the object returned from calling C<match> on a L<Path::Router>
instance. It contains all the information you would need to do any
dispatching nessecary.

=head1 METHODS

=over 4

=item B<new>

=item B<path>

This is the path that was matched.

=item B<mapping>

This is the mapping of your router part names to the actual parts of
the path. If your route had no "variables", then this will be an empty
HASH ref.

=item B<route>

This is the L<Path::Router::Route> instance that was matched.

=item B<target>

This method simply delegates to the C<target> method of the C<route>
that was matched.

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
