package Jasmine::Spy;
# ABSTRACT: Mocking library for perl inspired by Jasmine's spies

=head1 NAME

Jasmine::Spy

=head1 SYNOPSIS

    use Test::Spec;
    use Jasmine::Spy qw(spyOn stopSpying expectSpy);

    describe "FooClass" => sub {
        before each => sub {
            spyOn("BarClass", "bazMethod")->andReturn("Bop");
        };
        it "calls BarClass" => sub {
            FooClass->doTheThing();
            expectSpy("BarClass", "bazMethod")->toHaveBeenCalled();
        };
        after each => sub {
            stopSpying("BarClass");
        };
    };

=head1 Methods

Nothing is exported by default, but they cann all be pulled in with the :all tag

=item spyOn($invocant, $method)

This is the setup method to begin spying. $invocant may be either an object instance or the name of
a class. Spying on a Class will automatically spy on all instances of the class, even those created
before setting up the spy.  Spyng on an instance only effects that instance, not the class or
other instances of that class.

A "spy" object is returned from this call which will allow introspection and testing of
calls.  However there is no need to catch this, as other convience methods provide a better
way of performing the same introspection later.

=back

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
        expectSpy
        getCalls
    );
    %EXPORT_TAGS = (
        all => \@EXPORT_OK,
    );
}

sub spyOn {
    my ($proto, $method) = @_;
    if(exists($spies{$proto})){
        $spies{$proto}->spyOnMethod($proto, $method);
    }
    else {
        my $spy = Jasmine::Spy::Instance->new($proto, $method);
        $spies{$proto} = $spy;
    }
    return $spies{$proto};
}

sub stopSpying {
    my ($proto) = @_;
    my $spy = delete $spies{$proto};
    if($spy){
        $spy->stopSpying;
    }
}

sub expectSpy {
    my($proto, $method) = @_;
    $spies{$proto}->setCurrentMethod($method);
    return $spies{$proto};
}

sub getCalls {
    expectSpy(@_)->calls;
}

package Jasmine::Spy::Instance;

use warnings;
use strict;
use base qw(Test::Builder::Module);
use Test::Deep;

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

    $self->spyOnMethod($proto, $method);

    return $self;
}

sub stopSpying {
    my $self = shift;
    if(ref($self->{proto})){
        $self->{class}->meta->rebless_instance_back($self->{proto});
    }
    else {
        foreach my $method (keys %{$self->{original_methods}}){
            $self->{class}->meta->remove_method($method);
            $self->{class}->meta->add_method($method, $self->{original_methods}{$method});
        }
    }
}

sub spyOnMethod {
    my($self, $proto, $method) = @_;

    my $class = ref($proto) || $proto;
    my $metaclass = $proto->meta;
    $metaclass->make_mutable if ($metaclass->is_immutable);

    $self->{current_method} = $method;
    $self->{original_methods}{$method} = $metaclass->get_method($method);
    $metaclass->remove_method($method);
    $self->{spyClass} = $metaclass;
    $self->{responses}{$method} = undef;
    $metaclass->add_method($method, sub { $self->__callFake($method, @_); });
}

sub setCurrentMethod {
    my $self = shift;
    $self->{current_method} = shift;
}

sub __callFake {
    my $self = shift;
    my $method = shift;
    if($_[0] eq $self->{proto}){
        shift;
    }
    elsif(ref($_[0]) && !ref($self->{proto}) && $_[0]->isa($self->{class})){
        shift;
    }

    if(!exists $self->{calls}{$method}){
        my(@calls) = ();
        $self->{calls}{$method} = tie @calls, 'Jasmine::Spy::Instance::Calls';
    }
    push @{ $self->{calls}{$method} }, [@_];
    if(ref($self->{responses}{$method}) eq 'CODE'){
        return $self->{responses}{$method}->(@_);
    }
    elsif (ref($self->{responses}{$method}) eq 'Class::MOP::Method') {
        return $self->{responses}{$method}->execute(@_);
    }
    return $self->{responses}{$method};
}

sub andReturn {
    my $self = shift;
    my $ret  = shift;
    $self->{responses}{ $self->{current_method} } = $ret;
}

sub calls {
    my $self = shift;

    return $self->{calls}{ $self->{current_method} };
}

sub andCallThrough {
    my $self = shift;
    my $toCall;
    if(ref($self->{proto})){
        $toCall = $self->{class}->meta->get_method($self->{current_method});
    }
    else {
        $toCall = $self->{original_methods}{ $self->{current_method} };
    }

    $self->andReturn($toCall);
}

sub andCallFake {
    shift->andReturn(@_);
}

sub toHaveBeenCalled {
    my($self) = shift;

    my $tb = __PACKAGE__->builder;

    if ($self->__currentMethodHasBeenCalled){
        $tb->ok(1);
        return 1;
    }
    $tb->ok(0);
    return 0;
}

sub notToHaveBeenCalled {
    my($self) = shift;

    my $tb = __PACKAGE__->builder;

    if ($self->__currentMethodHasBeenCalled){
        $tb->ok(0);
        return 0;
    }
    $tb->ok(1);
    return 1;
}

sub __currentMethodHasBeenCalled {
    my $self = shift;
    if ($self->{calls}{ $self->{current_method} } && scalar(@{$self->{calls}{ $self->{current_method} }}) > 0){
        return 1;
    }
    return 0;
}

sub toHaveBeenCalledWith {
    my($self) = shift;

    my $tb = __PACKAGE__->builder;

    if ($self->__currentMethodHasBeenCalledWith(@_)){
        $tb->ok(1);
        return 1;
    }
    $tb->ok(0);
    return 0;
}

sub notToHaveBeenCalledWith {
    my($self) = shift;

    my $tb = __PACKAGE__->builder;

    if ($self->__currentMethodHasBeenCalledWith(@_)){
        $tb->ok(0);
        return 0;
    }
    $tb->ok(1);
    return 1;
}

sub __currentMethodHasBeenCalledWith {
    my $self = shift;
    if($self->__currentMethodHasBeenCalled && grep({eq_deeply([@_], $_)} @{ $self->{calls}{ $self->{current_method} } })){
        return 1;
    }
    return 0;
}

package Jasmine::Spy::Instance::Calls;
use Tie::Array;
use vars qw(@ISA);
@ISA = qw(Tie::StdArray);

sub first {
    my $self = shift;
    return $self->[0];
}

sub mostRecent {
    my $self = shift;
    return $self->[$#$self];
}

return 42;
