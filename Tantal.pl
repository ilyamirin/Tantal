#!/usr/bin/perl

use Dancer;
use Data::Dumper;
use Digest::MurmurHash qw(murmur_hash);
use Modern::Perl;
use Math::BigInt;
use Tie::Cache;

# -----init-----

tie( my %cached_index, 'Tie::Cache', 1000000, { Debug => 1 });

open (my $index, '<', config->{path_to_index}) or die $!;
my $numbers;
while (read($index, $numbers, 16) > 0) {
   my ($murmur, $offset, $key_size, $value_size) = unpack('L4', $numbers);
   $cached_index{$murmur} = [$offset, $key_size, $value_size];
}
close $index;

tie( my %state, 'Tie::Cache', 10, { Debug => 1 });

# -----init end -----

sub get_value {
    my ($key) = @_;

    my $murmur = murmur_hash($key);
    my ($offset, $key_size, $value_size) = @{ $cached_index{$murmur} };

    my $result;
    open (my $storage, '<', config->{path_to_storage}) or die $!;
    seek $storage, $offset + $key_size, 1;
    read $storage, $result, $value_size;
    close $storage;

    return unpack('u', $result);
  }
 
sub insert_value {
    my ($key, $value) = @_;

    my $murmur = murmur_hash($key);
    my $offset = -s config->{path_to_storage};
    my $printable_key = pack 'u', $key;  
    my $printable_value = pack 'u', $value;  
    my $key_size = length $printable_key;
    my $value_size = length $printable_value;

    open (my $storage, '>>', config->{path_to_storage}) or die $!;
    print $storage $printable_key;
    print $storage $printable_value;
    close $storage;
       
    open (my $index, '>>', config->{path_to_index}) or die $!;
    print $index pack('L4', $murmur, $offset, $key_size, $value_size); 
    close $index;
    $cached_index{$murmur} = [$offset, $key_size, $value_size];    
}

get '/' => sub {
    info params->{key} . ' GETted';
    return get_value(params->{key});
};

post '/' => sub {
    info params->{key} . ':'. params->{value} . ' POSTed';
    insert_value(params->{key}, params->{value});
    return 'OK';
};

dance;