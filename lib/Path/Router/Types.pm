package Path::Router::Types;
# ABSTRACT: A set of types that Path::Router uses

use Carp ();

use Type::Library
    -base,
    -declare => qw(PathRouterRouteValidationMap);
use Type::Utils -all;
use Types::Standard -types;
use Types::TypeTiny qw(TypeTiny);

declare PathRouterRouteValidationMap,
    as HashRef[TypeTiny];

# NOTE:
# canonicalize the route
# validators into a simple
# set of type constraints
# - SL
coerce PathRouterRouteValidationMap,
    from HashRef[Str | RegexpRef | TypeTiny],
    via {
        my %orig = %{ +shift };
        foreach my $key (keys %orig) {
            my $val = $orig{$key};
            if (ref $val eq 'Regexp') {
                $orig{$key} = declare(as Str, where{ /^$val$/ });
            }
            elsif (TypeTiny->check($val)) {
                $orig{$key} = $val;
            }
            else {
                $orig{$key} = dwim_type($val)
                    || Carp::confess "Could not locate type constraint named $val";
            }
        }
        return \%orig;
    };

1;

__END__

=pod

=head1 SYNOPSIS

  use Path::Router::Types;

=head1 DESCRIPTION

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
