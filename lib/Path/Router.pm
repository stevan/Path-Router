package Path::Router;
use Moose;

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:STEVAN';

use File::Spec::Unix ();

use Path::Router::Types;
use Path::Router::Route;
use Path::Router::Route::Match;

our $DEBUG = 0;

has 'routes' => (
    is      => 'ro', 
    isa     => 'ArrayRef[Path::Router::Route]',
    default => sub { [] },
);

sub add_route {
    my ($self, $path, %options) = @_;
    push @{$self->routes} => Path::Router::Route->new(
        path  => $path, 
        %options
    );
}

sub match {
    my ($self, $url) = @_;
    
    my @parts = grep { $_ } split '/' => File::Spec::Unix->canonpath($url);
    
    foreach my $route (@{$self->routes}) {
        my $mapping;
        
        eval {           
            
            warn "> Attempting to match ", $route->path, " to (", (join " / " => @parts), ")" if $DEBUG;
            
            if ($DEBUG) {
                warn "parts length: " . scalar @parts;
                warn "route length: " . $route->length;                
                warn "route length w/out optionals: " . $route->length_without_optionals;
                warn join ", " => @{$route->components};
            }
            
            # they must be the same length
            (
                scalar(@parts) >= $route->length_without_optionals &&
                scalar(@parts) <= $route->length 
            ) || die "LENGTHS DID NOT MATCH\n";
                
            warn "\t... They are the same length" if $DEBUG;
        
            my @components = @{$route->components};
            
            if ($route->has_defaults) {
                warn "\t... ", $route->path, " has a guide" if $DEBUG;
                $mapping = $route->create_default_mapping;
            }
        
            foreach my $i (0 .. $#components) {
                
                if (!defined $parts[$i] && $route->is_component_optional($components[$i])) {
                    next;
                }
                
                # if it is a variable (starts with a colon)
                if ($route->is_component_variable($components[$i])) {
                    my $name = $route->get_component_name($components[$i]);
                    
                    warn "\t\t... mapped ", $components[$i], " to ", $parts[$i] if $DEBUG;
                    
                    if (my $type = $route->has_validation_for($name)) {
                        
                        warn "\t\t\t... checking validation for $name against ", $type->name ," and ", $parts[$i] if $DEBUG;                            
                        
                        $type->check($parts[$i]) || die "VALIDATION DID NOT PASS\n";
                        
                        warn "\t\t\t\t... validation passed for $name with ", $parts[$i] if $DEBUG;
                    }
                    
                    $mapping->{$name} = $parts[$i];
                }
                else {
                    warn "\t\t... found a constant (", $components[$i], ")" if $DEBUG;
                    
                    ($components[$i] eq $parts[$i]) || die "CONSTANT DID NOT MATCH\n";
                    
                    warn "\t\t\t... constant matched" if $DEBUG;
                }
            }
        
        };
        unless ($@) {
            warn "+ ", $route->path, " matched ", $url if $DEBUG;
            
            return Path::Router::Route::Match->new(
                path    => (join "/" => @parts),
                route   => $route,
                mapping => $mapping || {},
            );
        }
        else {
            warn "~ got an exception here : ", $@ if $DEBUG;
            warn "\t- ", $route->path, " did not match ", $url, " because ", $@ if $DEBUG;
        }
        
    }
    
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

            if ($DEBUG) {
                warn "> Attempting to match ", $route->path, " to (", (join " / " => @keys), ")";
            }
            (
                @keys >= keys(%required) &&
                @keys <= (keys(%required) + keys(%optional) + keys(%match))
            ) || die "LENGTH DID NOT MATCH\n";

            if (my @missing = grep { ! exists $url_map{$_} } keys %required) {
                warn "missing: @missing" if $DEBUG;
                die "MISSING ITEM [@missing]\n";
            }

            if (my @extra = grep {
                    ! $required{$_} && ! $optional{$_} && ! $match{$_}
                } keys %url_map) {
                warn "extra: @extra" if $DEBUG;
                die "EXTRA ITEM [@extra]\n";
            }

            if (my @nomatch = grep {
                    exists $url_map{$_} and $url_map{$_} ne $match{$_}
                } keys %match) {
                warn "no match: @nomatch" if $DEBUG;
                die "NO MATCH [@nomatch]\n";
            }

            for my $component (@{$route->components}) {
                if ($route->is_component_variable($component)) {
                    warn "\t\t... found a variable ($component)" if $DEBUG;
                    my $name = $route->get_component_name($component);
                    
                    push @url => $url_map{$name}
                        unless
                        $route->is_component_optional($component) && 
                        $route->defaults->{$name}                 &&
                        $route->defaults->{$name} eq $url_map{$name};
                    
                }

                else {
                    warn "\t\t... found a constant ($component)" if $DEBUG;
                    
                    push @url => $component;
                }                    
                
                warn "+++ URL so far ... ", (join "/" => @url) if $DEBUG;
            }
            
        };
        unless ($@) {
            return join "/" => @url;
        }
        else {
            do {
                warn join "/" => @url;
                warn "... ", $@;
            } if $DEBUG;
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

=head2 Hey, wait, this is like RoR!

Yes, this is based on Ruby on Rails ActionController::Routing::Routes, 
however, it has one important difference. 

It is in Perl :)

=head1 METHODS

=over 4

=item B<new>

=item B<add_route ($path, ?%options)>

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

This is still a relatively new module, even though it has been 
sitting on my drive un-used for over a year now. We are only just 
now using it at $work, so there still may be bugs lurking. For that
very reason I have made the C<$DEBUG> variable more accessible 
so that you can turn on the verbose debug logging with:

  $Path::Router::DEBUG = 1;

And possibly help clear out some bugs lurking in the dark corners
of this module. 

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
