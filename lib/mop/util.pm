package mop::util;

use v5.16;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Package::Stash;
use Hash::Util::FieldHash;

use Sub::Exporter -setup => {
    exports => [qw[
        find_meta
        has_meta
        get_stash_for
        init_attribute_storage
        get_object_id
    ]]
};

sub find_meta { ${ get_stash_for( shift )->get_symbol('$METACLASS') || \undef } }
sub has_meta  {    get_stash_for( shift )->has_symbol('$METACLASS')  }

sub get_stash_for {
    state %STASHES;
    my $class = ref($_[0]) || $_[0];
    $STASHES{ $class } //= Package::Stash->new( $class )
}

sub get_object_id { Hash::Util::FieldHash::id( $_[0] ) }

sub register_object    { Hash::Util::FieldHash::register( $_[0] ) }
sub get_object_from_id { Hash::Util::FieldHash::id_2obj( $_[0] ) }

sub init_attribute_storage (\%) {
    &Hash::Util::FieldHash::fieldhash( $_[0] )
}

package mop::mro;

use strict;
use warnings;

sub get_linear_isa {
    my $class = shift;
    if (my $meta = mop::util::find_meta($class)) {
        # NOTE:
        # Roles have no ISA, but this question
        # is asked by the dispatcher so we need
        # to be able to handle it.
        # - SL
        return [ $meta->name ] if $meta->isa('mop::role');
        if (my $super = $meta->superclass) {
            return [ $meta->name, @{ get_linear_isa($super) || [] } ];
        } else {
            return [ $meta->name ];
        }
    } else {
        return mro::get_linear_isa($class);
    }
}

package mop::next;

use strict;
use warnings;

sub method {
    my ($invocant, @args) = @_;
    mop::internals::mro::call_method(
        $invocant,
        ${^CALLER}->[1],
        \@args,
        super_of => ${^CALLER}->[2]
    );
}

sub can {
    my ($invocant) = @_;
    my $method = mop::internals::mro::find_method(
        $invocant,
        ${^CALLER}->[1],
        super_of => ${^CALLER}->[2]
    );
    return unless $method;
    # NOTE:
    # we need to preserve any events 
    # that have been attached to this
    # method.
    # - SL
    return sub { $method->execute( shift, [ @_ ] ) }
        if Scalar::Util::blessed($method) && $method->isa('mop::method');
    return $method;
}

1;

__END__

=pod

=head1 NAME

mop::util - collection of utilities for the mop

=head1 DESCRIPTION

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little <stevan@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

