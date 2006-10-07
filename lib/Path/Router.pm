
package Path::Router;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Path::Router::Route;

use constant DEBUG => 0;

has 'routes' => (
    is  => 'ro', 
    isa => 'ArrayRef'
);

sub add_route {
    my ($self, $path, $guide) = @_;
    
    push @{$self->routes} => Path::Router::Route->new(
        path  => $path,
        guide => $guide,
    );
}

sub match {
    my ($self, $url) = @_;
    
    my @parts = grep { $_ } split '/' => $url;
    
    foreach my $route (@{$self->routes}) {
        my $mapping;
        eval {           
            
            warn "> Attempting to match " . $route->path . " to (" . (join " / " => @parts) . ")"
                if DEBUG;
            
            # they must be the same length
            (scalar @parts == $route->length) || die "LENGTHS DID NOT MATCH\n";
                
            warn "\t... They are the same length"
                if DEBUG;
        
            my @components = @{$route->components};
            
            if ($route->guide) {
                warn "\t... " . $route->path . " has a guide"
                    if DEBUG;
                $mapping = { %{$route->guide} };
            }
        
            foreach my $i (0 .. $#components) {
                # if it is a variable (starts with a colon)
                if ($components[$i] =~ /^\:(.*)$/) {
                    my $name = $1;
                    warn "\t\t... mapped " . $components[$i] . " to " . $parts[$i]
                        if DEBUG;
                    if (exists $mapping->{$name}) {
                        my $regexp = $mapping->{$name};
                        warn "\t\t\t... checking validation for $name against $regexp and " . $parts[$i]
                            if DEBUG;                            
                        ($parts[$i] =~ /^$regexp$/) || die "VALIDATION DID NOT PASS\n";
                        warn "\t\t\t\t... validation passed for $name with " . $parts[$i]
                            if DEBUG;
                    }
                    $mapping->{$name} = $parts[$i];
                }
                else {
                    warn "\t\t... found a constant (" . $components[$i] . ")"
                        if DEBUG;
                    ($components[$i] eq $parts[$i]) || die "CONSTANT DID NOT MATCH\n";
                    warn "\t\t\t... constant matched"
                        if DEBUG;
                }
            }
        
        };
        unless ($@) {
            warn "+ " . $route->path . " matched " . $url
                if DEBUG;
            return $mapping;
        }
        else {
            warn "\t- " . $route->path . " did not match " . $url . " because " . $@
                if DEBUG;
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

            warn "> Attempting to match " . $route->path . " to (" . (join " / " => @keys) . ")"
                if DEBUG;                
            
            (
                $route->length == scalar @keys ||
                scalar keys %{$route->guide} == scalar @keys
            ) || die "LENGTH DID NOT MATCH\n";
            
            my @components = @{$route->components};
        
            foreach my $i (0 .. $#components) {  
                
                # if it is a variable (starts with a colon)
                if ($components[$i] =~ /^\:(.*)$/) {
                    my $name = $1;
                    unless (exists $url_map{$name}) {
                        unless ($route->has_guide && exists $route->guide->{$name}) {
                            # NOTE:
                            # this will all get cleaned up in the end
                            die "MISSING ITEM\n"
                        }
                    }
                    push @url => $url_map{$name};
                    warn "\t\t... removing $name from url map"
                        if DEBUG;
                    delete $url_map{$name};
                }
                else {
                    warn "\t\t... found a constant (" . $components[$i] . ")"
                        if DEBUG;
                    push @url => $components[$i];
                    warn "\t\t... removing constant " . $components[$i] . " at key " . $reverse_url_map{$components[$i]} . " from url map"
                        if DEBUG;
                    delete $url_map{$reverse_url_map{$components[$i]}}
                        if $reverse_url_map{$components[$i]};                        
                        
                }                    
                
                warn "+++ URL so far ... " . (join "/" => @url)
                    if DEBUG;
            }
            
            warn "Remaining keys " . (join ", " => keys %url_map)
                if DEBUG;  
            
            foreach my $remaining_key (keys %url_map) {
                # some keys will not be in the URL, but 
                # we want to make sure they are a correct 
                # match for the URL
                if (exists $route->guide->{$remaining_key} && 
                    $route->guide->{$remaining_key} eq $url_map{$remaining_key}) {
                        
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
                warn "... " . $@;
            } if DEBUG;
        }
        
    }
    
}

no Moose; 1;

__END__

=pod

=head1 NAME

Path::Router - A tool for deconstructing paths

=head1 SYNOPSIS

  my $router = Path::Router->new;
  
  $router->add_route('blog' => {
      controller => 'blog',
      action     => 'index',
  });
  
  $router->add_route('blog/:year/:month/:day' => {
      controller => 'blog',
      action     => 'show_date',
      year       => qr/\d\d\d\d/,
      month      => qr/\d\d?/,
      day        => qr/\d\d?/,        
  });
  
  $router->add_route('blog/:action/:id' => {
      controller => 'blog',
      id         => qr/\d+/,
  });
  
  # ... in your dispatcher
  
  my $deconstructed_path_hash = $router->match('/blog/edit/15);
  
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

=head2 Hey, wait, this is like RoR!

Yes, this is based on Ruby on Rails ActionController::Routing::Routes, 
however, it has one important difference. 

It is in Perl :)

=head1 METHODS

=over 4

=item B<new>

=item B<add_route ($path, ?%guide)>

=item B<routes>

=item B<match ($path)>

=item B<uri_for (%path_descriptior)>

=item B<meta>

=back

=head1 AUTHORS

Stevan Little E<lt>stevan.little@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Stevan Little

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
