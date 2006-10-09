
package Path::Router::Route;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

has 'path'  => (
    is       => 'ro', 
    isa      => 'Str', 
    required => 1
);

has 'defaults' => (
    is        => 'ro', 
    isa       => 'HashRef', 
    predicate => {
        'has_defaults' => sub {
            scalar keys %{(shift)->{defaults}}
        }
    }
);

has 'validations' => (
    is  => 'ro', 
    isa => 'HashRef', 
    predicate => {
        'has_validations' => sub {
            scalar keys %{(shift)->{validations}}
        }
    }    
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

# misc

sub create_default_mapping {
    my $self = shift;
    +{ %{$self->defaults} }
}

sub has_validation_for {
    my ($self, $name) = @_;
    $self->validations->{$name};
}

# component checking

sub is_component_optional {
    my ($self, $component) = @_; 
    $component =~ /^\?\:/;    
}

sub is_component_variable {
    my ($self, $component) = @_; 
    $component =~ /^\??\:/; 
}

sub get_component_name {
    my ($self, $component) = @_;
    my ($name) = ($component =~ /^\??\:(.*)$/);        
    return $name;
}

# various types of lenths we need

sub length_without_optionals {
    my $self = shift;
    scalar grep { !$self->is_component_optional($_) } @{$self->components}
}

sub length_with_defaults_and_validations {
    my $self = shift;
    (scalar keys %{$self->defaults}) + (scalar keys %{$self->validations})
}

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

=item B<defaults>

=item B<has_defaults>

=item B<validations>

=item B<has_validations>

=item B<has_validation_for>

=back

=over 4

=item B<create_default_mapping>

=back

=head2 Component checks

=over 4

=item B<get_component_name ($component)>

=item B<is_component_optional ($component)>

=item B<is_component_variable ($component)>

=back

=head2 Length methods

=over 4

=item B<length_with_defaults_and_validations>

=item B<length_without_optionals>

=back

=head2 Introspection

=over 4

=item B<meta>

=back

=head1 AUTHORS

Stevan Little E<lt>stevan.little@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Stevan Little

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut