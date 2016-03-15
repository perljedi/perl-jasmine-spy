use Test::Spec;
use lib qw(t);
use Jasmine::Spy qw(spyOn);
use ExampleClass;

describe "spyOn" => sub {
	describe "an instance" => sub {
		my $example;
		before each => sub {
			$example = ExampleClass->new;
		};
		it "replaces original method" => sub {
			spyOn($example, 'foo');
			is($example->foo, undef);
		};
		it "only replaces the method on the instance, not the class" => sub {
			spyOn($example, 'foo');
			is(ExampleClass->foo, 'foo');
		};
		it "does not effect other methods" => sub {
			spyOn($example, 'foo');
			is($example->bar, 'bar');
		};
	};
	describe "a package" => sub {
		it "replaces the original method" => sub {
			spyOn("ExampleClass", "foo");
			is(ExampleClass->foo, undef);
		};
		it "also replaces instance methods" => sub {
			spyOn("ExampleClass", "foo");
			my $example = ExampleClass->new;
			is($example->foo, undef);
		}
	};
};

runtests;
