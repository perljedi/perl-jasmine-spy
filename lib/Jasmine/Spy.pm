use strict;
use warnings;

package Jasmine::Spy;
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Class::MOP;
my(%spies) = ();

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
    my $spy = Jasmine::Spy::Instance->new($proto, $method);
	$spies{$proto} = $spy;
	return $spy;
}

sub stopSpying {
	my($proto) = @_;
	while(exists $spies{$proto}){
		$spies{$proto}{class}->meta->rebless_instance_back($proto);
	}
}

package Jasmine::Spy::Instance;

sub new {
    my ($mp, $proto, $method) = @_;
    my $class = ref($proto) || $proto;
    eval "package $class; use metaclass;" unless ($proto->can("metaclass"));

    my $metaclass = $proto->meta;
    $metaclass->make_mutable if ($metaclass->is_immutable);

    my $self = {
        proto  => $proto,
        method => $method,
		class  => $class,
    };

    if (ref($proto)) {
        my $spyClass = Class::MOP::Class->create_anon_class(
            methods => {
                $method => sub { return undef },
            },
            superclasses => [$class],
        );
        $spyClass->rebless_instance($proto);
        $self->{spyClass} = $spyClass;
    }
    else {
        $self->{original_methods}{$method} = $metaclass->remove_method($method);
		$self->{spyClass} = $metaclass;
        $metaclass->add_method($method, sub { return undef; });
    }
    return bless($self, ref($mp) || $mp);
}

sub andReturn {
	my $self = shift;
	my $ret = shift;
	$self->{spyClass}->remove_method($self->{method});
	$self->{spyClass}->add_method($self->{method}, sub {
		return $ret;
	});
}

return 42;
