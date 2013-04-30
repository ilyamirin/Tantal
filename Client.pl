#!/usr/bin/env perl 

use Test::Simple tests => 4;

use Coro qw{async cede};
use HTTP::Request;
use Modern::Perl;
use LWP::UserAgent;
use String::Random qw{random_string};
use Time::HiRes qw{time};

use constant { 
    BASE_URL       => 'http://127.0.0.1:8080/?collection=test_collection',
    TOTAL_REQUESTS => 10000,
    TOTAL_AGENTS   => 10
};

my %requests;
say 'Start generating of ' . TOTAL_REQUESTS . ' random key<=>value pairs.';
$requests{random_string('cCcCcCc')} = random_string('cCcCcCcCcCcCcCc') for 1..TOTAL_REQUESTS;
say TOTAL_REQUESTS . ' random key<=>value pairs have been generated.';

my $req = HTTP::Request->new(POST => BASE_URL);
$req->content_type('application/x-www-form-urlencoded');

my ($is_ok, $is_not_ok, $n) = (0, 0, 0);
my ($start_loading, $stop_loading) = (time, 0);
for (keys %requests) {
    my $coro = async {
        $req->content("key=$_[0]&value=$_[1]");
        my $ua = LWP::UserAgent->new;
        return $ua->request($req)->is_success;
    } $_, $requests{$_};
    
    if ($coro->join) {
        $is_ok++;
    }
    else {
        $is_not_ok++;
    }
    
    my $sec = int(time - $start_loading); 
    say "$is_ok is ok, $is_not_ok is not ok, $sec seconds have passed." unless ++$n % 1000;
}

$stop_loading = time and sleep 1;

ok(($is_ok == TOTAL_REQUESTS and $is_not_ok == 0), 'All requests should be loadeded.');
ok(($stop_loading - $start_loading <= 60), 'All requests should be loadeded in a allowed time.');

($is_ok, $is_not_ok, $n) = (0, 0, 0);
($start_loading, $stop_loading) = (time, 0);
for (keys %requests) {
    my $coro = async {
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get(BASE_URL . "&key=$_[0]");
        return $res->is_success and $res->content eq $_[1];
    } $_, $requests{$_};

    if ($coro->join) {
        $is_ok++;
    }
    else {
        $is_not_ok++;
    }

    my $sec = int(time - $start_loading); 
    say "$is_ok is ok, $is_not_ok is not ok, $sec seconds have passed." unless ++$n % 1000;
}
$stop_loading = time;

ok(($is_ok == TOTAL_REQUESTS and $is_not_ok == 0), 'Values should be retrived for all keys.');
ok(($stop_loading - $start_loading <= 60), 'Values should be retrived for all keys in a allowed time.')



