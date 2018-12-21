use Mojo::Base -base;
use Test::Mojo;
use Test::More;

use Mojolicious::Lite;
plugin 'surveil' => {enable_param => 'x', path => '/some/path'};
get '/' => 'index';

my $t = Test::Mojo->new;

$t->get_ok('/')->element_exists_not('script');
$t->get_ok('/?x=1')->element_exists('script')
  ->text_like('script', qr{socket = new WebSocket\("ws://[^:]+:\d+/some/path"\)});

$t->websocket_ok('/some/path')->status_is(101);

done_testing;
__DATA__
@@ index.html.ep
<html>
<head>
<title>test surveil</title>
</head>
<body>
<button id="foo" class="bar baz">does this work?</button>
</html>
