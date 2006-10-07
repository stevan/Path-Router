
package Path::Router::Route;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

has 'path'  => (
    is       => 'ro', 
    isa      => 'Str', 
    required => 1
);

has 'components' => (
    is      => 'ro', 
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [ split '/' => (shift)->path ] }
);

has 'length' => (
    is      => 'ro', 
    isa     => 'Int',
    lazy    => 1,
    default => sub { scalar @{(shift)->components} }
);

has 'guide' => (
    is        => 'ro', 
    isa       => 'HashRef',
    predicate => {
        'has_guide' => sub {
            scalar keys %{(shift)->guide}
        }
    }
);

no Moose; 1

__END__

=pod

=head1 NAME

Path::Router::Route - An object to represent a route

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new (path => $path, ?(guide => $guide))>

=item B<path>

=item B<components>

=item B<length>

=item B<guide>

=item B<has_guide>

=item B<meta>

=back

=head1 AUTHORS

Stevan Little E<lt>stevan.little@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Stevan Little

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut