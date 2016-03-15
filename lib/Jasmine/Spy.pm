use strict;
use warnings;
package Jasmine::Spy;
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Class::MOP;

BEGIN{
	@EXPORT = ();
	@EXPORT_OK = qw(
		spyOn
	);
	%EXPORT_TAGS = (

	);
}

sub spyOn {
	my($proto, $method) = @_;
	my $class = ref($proto) || $proto;
	eval "package $class; use metaclass;" unless($proto->can("metaclass"));

	my $metaclass = $proto->meta;
	$metaclass->make_mutable if ($metaclass->is_immutable);

	if(ref($proto)){
		my $spyClass = Class::MOP::Class->create_anon_class(
		methods => {
			$method => sub { return undef },
		},
		superclasses => [$class],
		);
		$spyClass->rebless_instance($proto);
	}else{
		my $orig_method = $metaclass->remove_method($method);
		$metaclass->add_method($method, sub {return undef;});
	}
}

return 42;
