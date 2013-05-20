#!/usr/bin/perl

use Dancer;
use Data::Dumper;
use Digest::MurmurHash qw(murmur_hash);
use File::Touch;
use MIME::Base64;
use Modern::Perl;
use Tie::Cache;

# -----init-----

tie (my %cached_index, 'Tie::Cache', config->{max_elements}, { Debug => 0 });

opendir(my $dh, config->{path_to_index});
while (readdir $dh) {
    next unless /^(.+)\.index$/;
    info "Start loading index $_";
    open (my $index, '<', $_) || die "Can`t open index $_: $!";
    my $numbers;
    while (read($index, $numbers, 16) > 0) {
        my ($murmur, $offset, $key_size, $value_size) = unpack('L4', $numbers);
        $cached_index{$1}{$murmur} = [$offset, $key_size, $value_size];
    }
    close $index;
    info scalar(keys %{$cached_index{$1}}) . " row are loaded into index cache from $_.";
}
closedir $dh;

# -----init end -----

sub get_value {
    my ($collection, $key) = @_;

    my $murmur = murmur_hash($key);
    my ($offset, $key_size, $value_size) = @{ $cached_index{$collection}{$murmur} };

    my $storage = config->{path_to_storage} . $collection . '.store';

    my $result;
    open (my $fh, '<', $storage) || die $!;
    seek $fh, $offset + $key_size, 1;
    read $fh, $result, $value_size;
    close $fh;

    return unpack('u', $result);
}
 
sub insert_value {
    my ($collection, $key, $value) = @_;
    
    my $storage = config->{path_to_storage} . $collection . '.store';
    touch $storage unless -e $storage;
    my $index = config->{path_to_index} . $collection . '.index';
    touch $index unless -e $index;
    
    my $murmur = murmur_hash($key);
    my $offset = -s $storage;
    my $printable_key = pack 'u', $key;  
    my $printable_value = pack 'u', $value;  
    my $key_size = length $printable_key;
    my $value_size = length $printable_value;

    open (my $fh, '>>', $storage) || die $!;
    print $fh $printable_key;
    print $fh $printable_value;
    close $fh;
       
    open ($fh, '>>', $index) || die $!;
    print $fh pack('L4', $murmur, $offset, $key_size, $value_size); 
    close $fh;
    $cached_index{$collection}{$murmur} = [$offset, $key_size, $value_size];    
}

get '/:collection/:key' => sub {
    info params->{key} . ' GETted';
    return encode_base64(get_value(params->{collection}, params->{key}), '');
};

post '/:collection' => sub {
    info params->{key} . ' POSTed';
    insert_value(params->{collection}, params->{key}, decode_base64 params->{value});
    return 'OK';
};

dance;
