use Test::Spec;
use lib qw(t);
use Jasmine::Spy qw(spyOn stopSpying);
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
		it "can set a return value" => sub {
			spyOn($example, 'foo')->andReturn('faz');
			is($example->foo, 'faz');
		};
		it "can stop spying" => sub  {
			spyOn($example, 'foo');
			is($example->foo, undef);
			stopSpying($example);
			is($example->foo, 'foo');
		};
	};
	describe "a package" => sub {
		xit "replaces the original method" => sub {
			spyOn("ExampleClass", "foo");
			is(ExampleClass->foo, undef);
		};
		xit "can set a return value" => sub {
			spyOn("ExampleClass", 'foo')->andReturn('faz');
			is(ExampleClass->foo, 'faz');
		};
		xit "also replaces instance methods" => sub {
			spyOn("ExampleClass", "foo");
			my $example = ExampleClass->new;
			is($example->foo, undef);
		};
		it "can stop spying" => sub {
			spyOn("ExampleClass", "foo");
			is(ExampleClass::foo, undef);
			stopSpying("ExampleClass");
			is(ExampleClass::foo, 'foo');
		};
		# after each => sub {
		# 	stopSpying("ExampleClass");
		# };
	};
};

runtests;
