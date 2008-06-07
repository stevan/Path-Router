package Path::Router::Route::Match;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

has 'path'    => (is => 'ro', isa => 'Str',     required => 1);
has 'mapping' => (is => 'ro', isa => 'HashRef', required => 1);

has 'route'   => (
    is       => 'ro', 
    isa      => 'Path::Router::Route', 
    required => 1,
    handles  => [qw[target]]
);

no Moose; 1;

__END__

=pod

=head1 NAME

Path::Router::Route::Match - The result of a Path::Router match

=head1 SYNOPSIS

  use Path::Router::Route::Match;

=head1 DESCRIPTION

=head1 METHODS 

=over 4

=item B<mapping>

=item B<meta>

=item B<path>

=item B<route>

=item B<target>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
