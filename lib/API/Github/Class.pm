package API::Github::Class;

use Extorter;

# VERSION

sub import {
    my $class  = shift;
    my $target = caller;

    $class->extort::into($target, '*Data::Object::Class');
    $class->extort::into($target, '*API::Github::Signature');
    $class->extort::into($target, '*API::Github::Type');

    return;
}

1;
