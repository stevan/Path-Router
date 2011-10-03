package Path::Router::Route;
use Moose;
# ABSTRACT: An object to represent a route

use Carp qw(cluck);
use Path::Router::Types;

with 'MooseX::Clone';

has 'path'  => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'defaults' => (
    traits    => [ 'Copy' ],
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub { {} },
    predicate => {
        'has_defaults' => sub {
            scalar keys %{(shift)->{defaults}}
        }
    }
);

has 'validations' => (
    traits    => [ 'Copy' ],
    is        => 'ro',
    isa       => 'Path::Router::Route::ValidationMap',
    coerce    => 1,
    default   => sub { {} },
    predicate => {
        'has_validations' => sub {
            scalar keys %{(shift)->{validations}}
        }
    }
);

has 'components' => (
    traits  => [ 'NoClone' ],
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { [ grep {$_} split '/' => (shift)->path ] }
);

has 'length' => (
    traits  => [ 'NoClone' ],
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub { scalar @{(shift)->components} },
);

has 'length_without_optionals' => (
    traits  => [ 'NoClone' ],
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub {
        scalar grep { ! $_[0]->is_component_optional($_) }
            @{ $_[0]->components }
    },
);

has 'required_variable_component_names' => (
    traits     => [ 'NoClone' ],
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    lazy_build => 1,
);

has 'optional_variable_component_names' => (
    traits     => [ 'NoClone' ],
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    lazy_build => 1,
);

has 'target' => (
    # let this just get copied, we
    # assume cloning of this is not
    # what you would want
    is        => 'ro',
    isa       => 'Any',
    predicate => 'has_target'
);

sub BUILD {
    my $self = shift;

    return unless $self->has_validations;

    my %components = map { $self->get_component_name($_) => 1 }
                     grep { $self->is_component_variable($_) }
                     @{ $self->components };

    for my $validation (keys %{ $self->validations }) {
        if (!exists $components{$validation}) {
            cluck "Validation provided for component :$validation, but the"
                . " path " . $self->path . " doesn't contain a variable"
                . " component with that name";
        }
    }
}

sub _build_required_variable_component_names {
    my $self = shift;
    return [
        map { $self->get_component_name($_) }
        grep {
            $self->is_component_variable($_) &&
            ! $self->is_component_optional($_)
        }
        @{ $self->components }
    ];
}

sub _build_optional_variable_component_names {
    my $self = shift;
    return [
        map { $self->get_component_name($_) }
        grep {
            $self->is_component_variable($_) &&
            $self->is_component_optional($_)
        }
        @{ $self->components }
    ];
}

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

sub match {
    my ($self, $parts) = @_;

    return unless (
        @$parts >= $self->length_without_optionals &&
        @$parts <= $self->length
    );

    my @parts = @$parts; # for shifting

    my $mapping = $self->has_defaults ? $self->create_default_mapping : {};

    for my $c (@{ $self->components }) {
        unless (@parts) {
            die "should never get here: " .
                "no \@parts left, but more required components remain"
                if ! $self->is_component_optional($c);
            last;
        }
        my $part = shift @parts;

        if ($self->is_component_variable($c)) {
            my $name = $self->get_component_name($c);
            if (my $v = $self->has_validation_for($name)) {
                return unless $v->check($part);
            }
            $mapping->{$name} = $part;
        } else {
            return unless $c eq $part;
        }
    }

    return Path::Router::Route::Match->new(
        path    => join ('/', @$parts),
        route   => $self,
        mapping => $mapping,
    );
}

sub generate_match_code {
    my $self = shift;
    my $pos = shift;
    my @regexp;
    my @variables;

    foreach my $c (@{$self->components}) {
        my $re;
        if ($self->is_component_variable($c)) {
            $re = "([^\\/]+)";
            push @variables, $self->get_component_name($c);
        } else {
            $re = $c;
            $re =~ s/([()])/\\$1/g;
        }
        $re = "\\/$re";
        if ($self->is_component_optional($c)) {
            $re = "(?:$re)?";
        }

        push @regexp, $re;
    }

    $regexp[0] = '' unless defined $regexp[0];

    $regexp[0] =~ s/^\\\///;
    my $regexp = '';
    while (my $piece = pop @regexp) {
        $regexp = "(?:$piece$regexp)";
    }

    my $code = "#line " . __LINE__ . ' "' . __FILE__ . "\"\n" .
        "print STDERR \"Attempting to match " . $self->path . " against \$path\\n\" if Path::Router::DEBUG();\n" .
        "print STDERR \"   regexp is $regexp\\n\" if Path::Router::DEBUG();\n" .
        "if (\$path =~ /^$regexp\$/) {\n" .
        "    # " . $self->path . "\n"
    ;
    if (@variables) {
        $code .= "    my %captures = (\n";
        foreach my $i (0..$#variables) {
            my $name = $variables[$i];
            $name =~ s/'/\\'/g;
            $code .= "        '$name' => \$" . ($i + 1) . " || '',\n";
        }
        $code .= "    );\n";
    }
    $code .=
        "    my \$route = \$routes->[$pos];\n" .
        "    my \$valid = 1;\n"
    ;
    ;
    if ($self->has_defaults) {
        $code .=
            "    my \$mapping = \$route->create_default_mapping;\n";
        ;
    } else {
        $code .=
            "    my \$mapping =  {};\n"
        ;
    }

    if (@variables) {
        $code .=
            "    my \$validations = \$route->validations;\n" .
            "    while(my(\$key, \$value) = each \%captures) {\n" .
            "        next unless defined \$value && length \$value;\n"
        ;

        my $if = "if";
        foreach my $v (@variables) {
            if ($self->has_validation_for($v)) {
                $code .=
                    "        $if (\$key eq '$v') {\n" .
                    "            my \$v = \$validations->{$v};\n" .
                    "            if (! \$v->check(\$value)) {\n" .
                    "                print STDERR \"$v failed validation\\n\" if Path::Router::DEBUG;\n" .
                    "                \$valid = 0;\n" .
                    "            }\n" .
                    "        }\n"
                ;
                $if = "elsif";
            }
        }

        $code .=
            "        \$mapping->{\$key} = \$value;\n" .
            "    }\n"
        ;
    }
    $code .=
        "    if (\$valid) {\n" .
        "        print STDERR \"match success\\n\" if Path::Router::DEBUG();\n" .
        "        return bless({\n" .
        "            path => \$path,\n" .
        "            route => \$route,\n" .
        "            mapping => \$mapping,\n" .
        "        }, 'Path::Router::Route::Match');\n" .
        "    }\n" .
        "}\n"
    ;

    return $code;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 DESCRIPTION

This object is created by L<Path::Router> when you call the
C<add_route> method. In general you won't ever create these objects
directly, they will be created for you and you may sometimes
introspect them.

=head1 METHODS

=over 4

=item B<new (path => $path, ?%options)>

=item B<path>

=item B<target>

=item B<has_target>

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

=item B<match>

=item B<generate_match_code>

=back

=head2 Component checks

=over 4

=item B<get_component_name ($component)>

=item B<is_component_optional ($component)>

=item B<is_component_variable ($component)>

=back

=head2 Length methods

=over 4

=item B<length_without_optionals>

=back

=head2 Introspection

=over 4

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

=begin Pod::Coverage

BUILD

=end Pod::Coverage

=cut
