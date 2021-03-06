package Catmandu::Store;

use Catmandu::Sane;

our $VERSION = '1.0504';

use Hash::Util::FieldHash qw(fieldhash);
use Sub::Quote qw(quote_sub);
use Moo::Role;
use MooX::Aliases;
use namespace::clean;

with 'Catmandu::Logger';

has bag_class => (is => 'ro', default => sub {ref($_[0]) . '::Bag'},);

has default_bag => (is => 'ro', default => sub {'data'},);

has bags => (is => 'ro', default => sub {+{}},);

has key_prefix => (is => 'lazy', default => sub {'_'},);

has id_key => (is => 'lazy', alias => 'id_field');

sub key_for {
    $_[0]->key_prefix . $_[1];
}

sub _build_id_key {
    $_[0]->key_for('id');
}

{
    fieldhash my %bag_instances;

    sub bag {
        my $self = shift;
        my $name = shift // $self->default_bag;
        $bag_instances{$self}{$name} ||= do {
            my $pkg = $self->bag_class;
            if (my $options = $self->bags->{$name}) {
                $options = {%$options};
                if (my $plugins = delete $options->{plugins}) {
                    $pkg = $pkg->with_plugins($plugins);
                }
                $pkg->new(%$options, store => $self, name => $name);
            }
            else {
                $pkg->new(store => $self, name => $name);
            }
        };
    }
}

# forward methods to default bag
{
    my $pkg      = __PACKAGE__;
    my @delegate = (

        # Catmandu::Iterable methods
        qw(to_array count slice each tap any many all map reduce first rest
            take pluck invoke contains includes group interleave max min
            benchmark),

        # Catmandu::Addable methods
        qw(add add_many commit),

        # Catmandu::Bag methods
        qw(get delete delete_all get_or_add to_hash),
    );

    for my $sub (@delegate) {
        quote_sub("${pkg}::${sub}",
            "my \$self = shift; \$self->bag->${sub}(\@_)");
    }
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store - Namespace for packages that can make data persistent

=head1 SYNOPSIS

    # From the command line

    $ catmandu import JSON into MongoDB --database_name 'bibliography' < data.json

    $ catmandu export MongoDB --database_name 'bibliography' to YAML
    $ catmandu export MongoDB --database_name 'bibliography' --query '{"PublicationYear": "1937"}'
    $ catmandu count  MongoDB --database_name 'bibliography' --query '{"PublicationYear": "1937"}'

    # From Perl
    use Catmandu;

    my $store = Catmandu->store('MongoDB',database_name => 'bibliography');

    my $obj1 = $store->bag->add({ name => 'Patrick' });

    printf "obj1 stored as %s\n" , $obj1->{_id};

    # Force an id in the store
    my $obj2 = $store->bag->add({ _id => 'test123' , name => 'Nicolas' });

    my $obj3 = $store->bag->get('test123');

    $store->bag->delete('test123');

    $store->bag->delete_all;

    # Some stores can be searched
    my $hits = $store->bag->search(query => 'name:Patrick');

=head1 DESCRIPTION

A Catmandu::Store is a stub for Perl packages that can store data into
databases or search engines. The database as a whole is called a 'store'.
Databases also have compartments (e.g. tables) called L<Catmandu::Bag>-s.
Some stores can be searched using L<Catmandu::Searchable> methods.

=head1 CONFIGURATION

=over

=item default_bag

The name of the bag to use if no explicit bag is given. Default is 'data'.

    my $store = Catmandu::Store::MyDB->new(default_bag => 'stuff');
    # this will return the stuff bag
    my $bag = $store->bag;

=item bags

Specify configuration for individual bags.

    my $store = Catmandu::Store::Hash->new(
        bags => {stuff => {plugins => ['Datestamps']}});
    # this bag will use the L<Catmandu::Plugin::Datestamps> role
    $store->bag('stuff')
    # this bag won't
    $store->bag('otherbag')

=item bag_class

An optional custom class to use for bags. Default is C<Bag> in the store's
namespace. This class should consume the L<Catmandu::Bag> role.

    # this will use the Catmandu::Store::MyDB::Bag class for bags
    Catmandu::Store::MyDB->new()
    # this will use MyBag
    Catmandu::Store::MyDB->new(bag_class => 'MyBag')

=item key_prefix

Use a custom prefix to mark the reserved or special keys that the store uses.
By default an underscore gets prependend. The only special key in a normal
store is '_id'. L<Catmandu::Plugin::Versioning> will also use '_version'. Other
plugins or stores may add their own special keys.

    # this store will use the my_id key to hold id's
    Catmandu::Store::MyDB->new(key_prefix => 'my_')

=item id_key

Define a custom key to hold id's for all bags of this store. See C<key_prefix>
for the default value. Also aliased as C<id_field>. Note that this can also be
overriden on a per bag basis.

=back

=head1 METHODS

=head2 bag($name)

Create or retieve a bag with name C<$name>. Returns a L<Catmandu::Bag>.

=head2 key_for($key)

Helper method that applies C<key_prefix> to the C<$key> given.

=head2 log

Return the current logger. Can be used when creating your own Stores.

E.g.

    package Catmandu::Store::Hash;

    ...

    sub generator {
        my ($self) = @_;

        $self->log->debug("generating record");
        ...
    }

See also: L<Catmandu> for activating the logger in your main code.

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::Searchable>

=cut
