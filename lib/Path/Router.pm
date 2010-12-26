package Path::Router;
use Moose;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

use File::Spec::Unix ();

use Path::Router::Types;
use Path::Router::Route;
use Path::Router::Route::Match;

use constant DEBUG => exists $ENV{PATH_ROUTER_DEBUG} ? $ENV{PATH_ROUTER_DEBUG} : 0;

has 'routes' => (
    is      => 'ro',
    isa     => 'ArrayRef[Path::Router::Route]',
    default => sub { [] },
);

has 'route_class' => (
    is      => 'ro',
    isa     => 'ClassName',
    default => 'Path::Router::Route',
);

has 'inline' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
    trigger => sub { $_[0]->clear_match_code }
);

has 'match_code' => (
    is         => 'rw',
    isa        => 'CodeRef',
    lazy_build => 1,
    clearer    => 'clear_match_code'
);

sub _build_match_code {
    my $self = shift;

    my @code;
    my $i = 0;
    foreach my $route (@{$self->routes}) {
        push @code, $route->generate_match_code($i++);
    }

    my $code = "sub {\n" .
        "#line " . __LINE__ . ' "' . __FILE__ . "\"\n" .
        "   my \$self = shift;\n" .
        "   my \$path = shift;\n" .
        "   my \$routes = \$self->routes;\n" .
        join("\n", @code) .
        "#line " . __LINE__ . ' "' . __FILE__ . "\"\n" .
        "   print STDERR \"match failed\\n\" if DEBUG();\n" .
        "   return ();\n" .
        "}"
    ;
    # print STDERR $code;
    eval $code or warn $@;
}

sub add_route {
    my ($self, $path, %options) = @_;
    push @{$self->routes} => $self->route_class->new(
        path  => $path,
        %options
    );
    $self->clear_match_code;
}

sub insert_route {
    my ($self, $path, %options) = @_;
    my $at = delete $options{at} || 0;

    my $route = $self->route_class->new(
        path  => $path,
        %options
    );
    my $routes = $self->routes;

    if (! $at) {
        unshift @$routes, $route;
    } elsif ($#{$routes} < $at) {
        push @$routes, $route;
    } else {
        splice @$routes, $at, 0, $route;
    }
    $self->clear_match_code;
}

sub include_router {
    my ($self, $path, $router) = @_;

    ($path eq '' || $path =~ /\/$/)
        || confess "Path is either empty of ends with a /";

    push @{ $self->routes } => map {
            $_->clone( path => ($path . $_->path) )
        } @{ $router->routes };
    $self->clear_match_code;
}

sub match {
    my ($self, $url) = @_;

    if ($self->inline) {
        $url =~ s|/{2,}|/|g;                          # xx////xx  -> xx/xx
        $url =~ s{(?:/\.)+(?:/|\z)}{/}g;              # xx/././xx -> xx/xx
        $url =~ s|^(?:\./)+||s unless $url eq "./";   # ./xx      -> xx
        $url =~ s|^/(?:\.\./)+|/|;                    # /../../xx -> xx
        $url =~ s|^/\.\.$|/|;                         # /..       -> /
        $url =~ s|/\z|| unless $url eq "/";           # xx/       -> xx
        $url =~ s|^/||; # Path::Router specific. remove first /

        return $self->match_code->($self, $url);
    } else {
        my @parts = grep { defined $_ and length $_ }
            split '/' => File::Spec::Unix->canonpath($url);

        for my $route (@{$self->routes}) {
            my $match = $route->match(\@parts) or next;
            return $match;
        }
    }
    return;
}

sub uri_for {
    my ($self, %orig_url_map) = @_;

    # anything => undef is useless; ignore it and let the defaults override it
    for (keys %orig_url_map) {
        delete $orig_url_map{$_} unless defined $orig_url_map{$_};
    }

    foreach my $route (@{$self->routes}) {
        my @url;
        eval {

            my %url_map = %orig_url_map;

            my %reverse_url_map = reverse %url_map;

            my %required = map {( $_ => 1 )}
                @{ $route->required_variable_component_names };

            my %optional = map {( $_ => 1 )}
                @{ $route->optional_variable_component_names };

            my %url_defaults;

            my %match = %{$route->defaults || {}};

            for my $component (keys(%required), keys(%optional)) {
                next unless exists $match{$component};
                $url_defaults{$component} = delete $match{$component};
            }
            # any remaining keys in %defaults are 'extra' -- they don't appear
            # in the url, so they need to match exactly rather than being
            # filled in

            %url_map = (%url_defaults, %url_map);

            my @keys = keys %url_map;

            if (DEBUG) {
                warn "> Attempting to match ", $route->path, " to (", (join " / " => @keys), ")";
            }
            (
                @keys >= keys(%required) &&
                @keys <= (keys(%required) + keys(%optional) + keys(%match))
            ) || die "LENGTH DID NOT MATCH\n";

            if (my @missing = grep { ! exists $url_map{$_} } keys %required) {
                warn "missing: @missing" if DEBUG;
                die "MISSING ITEM [@missing]\n";
            }

            if (my @extra = grep {
                    ! $required{$_} && ! $optional{$_} && ! $match{$_}
                } keys %url_map) {
                warn "extra: @extra" if DEBUG;
                die "EXTRA ITEM [@extra]\n";
            }

            if (my @nomatch = grep {
                    exists $url_map{$_} and $url_map{$_} ne $match{$_}
                } keys %match) {
                warn "no match: @nomatch" if DEBUG;
                die "NO MATCH [@nomatch]\n";
            }

            for my $component (@{$route->components}) {
                if ($route->is_component_variable($component)) {
                    warn "\t\t... found a variable ($component)" if DEBUG;
                    my $name = $route->get_component_name($component);

                    push @url => $url_map{$name}
                        unless
                        $route->is_component_optional($component) &&
                        $route->defaults->{$name}                 &&
                        $route->defaults->{$name} eq $url_map{$name};

                }

                else {
                    warn "\t\t... found a constant ($component)" if DEBUG;

                    push @url => $component;
                }

                warn "+++ URL so far ... ", (join "/" => @url) if DEBUG;
            }

        };
        unless ($@) {
            return join "/" => grep { defined } @url;
        }
        else {
            do {
                warn join "/" => @url;
                warn "... ", $@;
            } if DEBUG;
        }

    }

    return undef;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Path::Router - A tool for routing paths

=head1 SYNOPSIS

  my $router = Path::Router->new;

  $router->add_route('blog' => (
      defaults => {
          controller => 'blog',
          action     => 'index',
      },
      # you can provide a fixed "target"
      # for a match as well, this can be
      # anything you want it to be ...
      target => My::App->get_controller('blog')->get_action('index')
  ));

  $router->add_route('blog/:year/:month/:day' => (
      defaults => {
          controller => 'blog',
          action     => 'show_date',
      },
      # validate with ...
      validations => {
          # ... raw-Regexp refs
          year       => qr/\d{4}/,
          # ... custom Moose types you created
          month      => 'NumericMonth',
          # ... Moose anon-subtypes created inline
          day        => subtype('Int' => where { $_ <= 31 }),
      }
  ));

  $router->add_route('blog/:action/?:id' => (
      defaults => {
          controller => 'blog',
      },
      validations => {
          action  => qr/\D+/,
          id      => 'Int',  # also use plain Moose types too
      }
  ));

  # even include other routers
  $router->include_router( 'polls/' => $another_router );

  # ... in your dispatcher

  # returns a Path::Router::Route::Match object
  my $match = $router->match('/blog/edit/15');

  # ... in your code

  my $uri = $router->uri_for(
      controller => 'blog',
      action     => 'show_date',
      year       => 2006,
      month      => 10,
      day        => 5,
  );

=head1 DESCRIPTION

This module provides a way of deconstructing paths into parameters
suitable for dispatching on. It also provides the inverse in that
it will take a list of parameters, and construct an appropriate
uri for it.

=head2 Reversable

This module places a high degree of importance on reversability.
The value produced by a path match can be passed back in and you
will get the same path you originally put in. The result of this
is that it removes ambiguity and therefore reduces the number of
possible mis-routings.

=head2 Verifyable

This module also provides additional tools you can use to test
and verify the integrity of your router. These include:

=over 4

=item *

An interactive shell in which you can test various paths and see the
match it will return, and also test the reversability of that match.

=item *

A L<Test::Path::Router> module which can be used in your applications
test suite to easily verify the integrity of your paths.

=back

=head1 METHODS

=over 4

=item B<new>

=item B<add_route ($path, ?%options)>

Adds a new route to the I<end> of the routes list.

=item B<insert_route ($path, %options)>

Adds a new route to the routes list. You may specify an C<at> parameter, which would
indicate the position where you want to insert your newly created route. The C<at>
parameter is the C<index> position in the list, so it starts at 0.

Examples:

    # You have more than three paths, insert a new route at
    # the 4th item
    $router->insert_route($path => (
        at => 3, %options
    ));

    # If you have less items than the index, then it's the same as
    # as add_route -- it's just appended to the end of the list
    $router->insert_route($path => (
        at => 1_000_000, %options
    ));

    # If you want to prepend, omit "at", or specify 0
    $router->insert_Route($path => (
        at => 0, %options
    ));

=item B<include_router ( $path, $other_router )>

These extracts all the route from C<$other_router> and includes them into
the invocant router and prepends C<$path> to all their paths.

It should be noted that this does B<not> do any kind of redispatch to the
C<$other_router>, it actually extracts all the paths from C<$other_router>
and inserts them into the invocant router. This means any changes to
C<$other_router> after inclusion will not be reflected in the invocant.

=item B<routes>

=item B<match ($path)>

Return a L<Path::Router::Route::Match> object for the first route that matches the
given C<$path>, or C<undef> if no routes match.

=item B<uri_for (%path_descriptor)>

Find the path that, when passed to C<< $router->match >>, would produce the
given arguments.  Returns the path without any leading C</>.  Returns C<undef>
if no routes match.

=item B<meta>

=back

=head1 DEBUGGING

You can turn on the verbose debug logging with the C<PATH_ROUTER_DEBUG>
environment variable.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
