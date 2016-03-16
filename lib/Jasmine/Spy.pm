package Jasmine::Spy;
# ABSTRACT: Mocking library for perl inspired by Jasmine's spies

=head1 NAME

Jasmine::Spy

=cut

use strict;
use warnings;
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Class::MOP;


my (%spies) = ();

BEGIN {
    @EXPORT    = ();
    @EXPORT_OK = qw(
        spyOn
        stopSpying
    );
    %EXPORT_TAGS = (

    );
}

sub spyOn {
    my ($proto, $method) = @_;
    if(exists($spies{$proto})){
        $spies{$proto}->setSpyMethod($proto, $method);
    }
    else {
        my $spy = Jasmine::Spy::Instance->new($proto, $method);
        $spies{$proto} = $spy;
    }
    return $spies{$proto};
}

sub stopSpying {
    my ($proto) = @_;
    if(ref($proto)){
        while (exists $spies{$proto}) {
            my $spy = delete $spies{$proto};
            $spy->{class}->meta->rebless_instance_back($proto);
        }
    }
    else {

    }
}

package Jasmine::Spy::Instance;

sub new {
    my ($mp, $proto, $method) = @_;
    my $class = ref($proto) || $proto;
    eval "package $class; use metaclass;" unless ($proto->can("metaclass"));


    my $self = bless(
        {
            proto => $proto,
            class => $class,
        },
        ref($mp) || $mp
    );
    if (ref($proto)) {
        my $spyClass = Class::MOP::Class->create_anon_class(superclasses => [$class]);
        $spyClass->rebless_instance($proto);
        $self->{spyClass} = $spyClass;
    }

    $self->setSpyMethod($proto, $method);

    return $self;
}

sub setSpyMethod {
    my($self, $proto, $method) = @_;

    my $class = ref($proto) || $proto;
    my $metaclass = $proto->meta;
    $metaclass->make_mutable if ($metaclass->is_immutable);

    $self->{current_method} = $method;
    $self->{original_methods}{$method} = $metaclass->remove_method($method);
    $self->{spyClass} = $metaclass;
    $metaclass->add_method($method, sub { return undef; });
}

sub andReturn {
    my $self = shift;
    my $ret  = shift;
    $self->{spyClass}->remove_method($self->{current_method});
    $self->{spyClass}->add_method(
        $self->{current_method},
        sub {
            return $ret;
        }
    );
}

return 42;
