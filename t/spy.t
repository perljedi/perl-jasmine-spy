use Test::Spec;
use lib qw(t);
use Jasmine::Spy qw(:all);
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
		it "can validate that the spy method was called" => sub {
			spyOn($example, 'foo');
			$example->foo;
			expectSpy($example, 'foo')->toHaveBeenCalled();
		};
		it "can validate that the spy method was called with specific arguments" => sub {
			spyOn($example, 'foo');
			$example->foo('baz');
			expectSpy($example, 'foo')->toHaveBeenCalledWith('baz');
		};
		it "can validate that the spy method was never called" => sub {
			spyOn($example, 'foo');
			expectSpy($example, 'foo')->notToHaveBeenCalled();
		};
		it "can validate that the spy method was not called with specific arguments" => sub {
			spyOn($example, 'foo');
			$example->foo('baz');
			expectSpy($example, 'foo')->notToHaveBeenCalledWith('ban');
		};
		it "can stop spying" => sub  {
			spyOn($example, 'foo');
			stopSpying($example);
			is($example->foo, 'foo');
		};
	};
	describe "a package" => sub {
		it "replaces the original method" => sub {
			spyOn("ExampleClass", "foo");
			is(ExampleClass->foo, undef);
		};
		it "can set a return value" => sub {
			spyOn("ExampleClass", 'foo')->andReturn('faz');
			is(ExampleClass->foo, 'faz');
		};
		it "also replaces instance methods" => sub {
			spyOn("ExampleClass", "foo");
			my $example = ExampleClass->new;
			is($example->foo, undef);
		};
		it "can validate that the spy method was called" => sub {
			spyOn("ExampleClass", "foo");
			ExampleClass->foo;
			expectSpy("ExampleClass", 'foo')->toHaveBeenCalled();
		};
		it "can validate that the spy method was called with specific arguments" => sub {
			spyOn("ExampleClass", "foo");
			ExampleClass->foo('bat');
			expectSpy("ExampleClass", 'foo')->toHaveBeenCalledWith('bat');
		};
		it "can validate that the spy method was never called" => sub {
			spyOn("ExampleClass", "foo");
			expectSpy("ExampleClass", 'foo')->notToHaveBeenCalled();
		};
		it "can validate that the spy method was not called with specific arguments" => sub {
			spyOn("ExampleClass", "foo");
			ExampleClass->foo('bat');
			expectSpy("ExampleClass", 'foo')->notToHaveBeenCalledWith('bar');
		};
		it "can stop spying" => sub {
			spyOn("ExampleClass", "foo");
			stopSpying("ExampleClass");
			is(ExampleClass::foo, 'foo');
		};
		after each => sub {
			stopSpying("ExampleClass");
		};
	};
};

runtests;
