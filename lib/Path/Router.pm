package Path::Router;
use Moose;

our $VERSION   = '0.02';
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
                scalar(@parts) == $route->length ||
                scalar(@parts) == $route->length_without_optionals
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
    
    my @keys = keys %orig_url_map;

    foreach my $route (@{$self->routes}) {
        my @url;
        eval {
            
            my %url_map = %orig_url_map;
            
            my %reverse_url_map = reverse %url_map;

            warn "> Attempting to match ", $route->path, " to (", (join " / " => @keys), ")" if $DEBUG;                
            
            (
                scalar @keys == $route->length ||
                scalar @keys == $route->length_with_defaults_and_validations
            ) || die "LENGTH DID NOT MATCH\n";
            
            my @components = @{$route->components};
        
            foreach my $i (0 .. $#components) {  
                
                # if it is a variable (starts with a colon)
                if ($route->is_component_variable($components[$i])) {
                    my $name = $route->get_component_name($components[$i]);
                    
                    unless (exists $url_map{$name}) {
                        
                        unless ($route->has_defaults && exists $route->defaults->{$name}) {
                            # NOTE:
                            # this will all get cleaned up in the end
                            die "MISSING ITEM\n"
                        }
                        
                    }

                    push @url => $url_map{$name}
                        unless $route->is_component_optional($components[$i]) && 
                               $route->defaults->{$name}                      &&
                               $route->defaults->{$name} eq $url_map{$name};
                    
                    warn "\t\t... removing $name from url map" if $DEBUG;
                    
                    delete $url_map{$name};
                }
                else {
                    warn "\t\t... found a constant (", $components[$i], ")" if $DEBUG;
                    
                    push @url => $components[$i];
                    
                    warn "\t\t... removing constant ", $components[$i], " at key ", $reverse_url_map{$components[$i]}, " from url map" if $DEBUG;
                    
                    delete $url_map{$reverse_url_map{$components[$i]}}
                        if $reverse_url_map{$components[$i]};                        
                        
                }                    
                
                warn "+++ URL so far ... ", (join "/" => @url) if $DEBUG;
            }
            
            warn "Remaining keys ", (join ", " => keys %url_map) if $DEBUG;  
            
            foreach my $remaining_key (keys %url_map) {
                # some keys will not be in the URL, but 
                # we want to make sure they are a correct 
                # match for the URL
                if (exists $route->defaults->{$remaining_key} && 
                    $route->defaults->{$remaining_key} eq $url_map{$remaining_key}) {
                        
                    delete $url_map{$remaining_key};
                }
            }
            
            (scalar keys %url_map == 0) || die "NOT ALL KEYS EXHAUSTED\n";
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
    
}

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

=item B<uri_for (%path_descriptior)>

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
