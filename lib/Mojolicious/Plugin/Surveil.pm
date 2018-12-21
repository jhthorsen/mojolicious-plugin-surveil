package Mojolicious::Plugin::Surveil;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::JSON qw(decode_json encode_json);

our $VERSION = '0.02';

sub register {
  my ($self, $app, $config) = @_;

  $config->{enable_param} ||= '_surveil';
  $config->{events}       ||= [qw(blur click focus touchstart touchcancel touchend)];
  $config->{path}         ||= '/mojolicious/plugin/surveil';

  push @{$app->renderer->classes}, __PACKAGE__;
  $app->hook(after_render => sub { _hook_after_render($config, @_) });
  $app->routes->websocket($config->{path})->to(cb => sub { _action_ws($config, @_) });
}

sub _action_ws {
  my $config = shift;
  my $c      = shift->inactivity_timeout(60);
  my $log    = $c->app->log;

  $c->on(
    message => sub {
      my $action = decode_json $_[1];
      my ($type, $target) = delete @$action{qw(type target)};
      $log->debug(qq(Event "$type" on "$target" @{[encode_json $action]}));
    }
  );
}

sub _hook_after_render {
  my ($config, $c, $output, $format) = @_;
  return if $format ne 'html';
  return if !$c->param($config->{enable_param});

  my $scheme = $c->req->url->to_abs->scheme || 'http';
  $scheme =~ s!^http!ws!;

  my $js = $c->render_to_string(
    template    => 'mojolicious/plugin/surveil',
    events      => encode_json($config->{events}),
    surveil_url => $c->url_for($config->{path})->to_abs->scheme($scheme),
  );

  $$output =~ s!</head>!$js</head>!;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Surveil - Surveil user actions

=head1 VERSION

0.02

=head1 DESCRIPTION

L<Mojolicious::Plugin::Surveil> is a plugin which allow you to see every
event a user trigger on your web page. It is meant as a debug tool for
seeing events, even if the browser does not have a JavaScript console.

CAVEAT: The JavaScript that is injected require WebSocket in the browser to
run. The surveil events are attached to the "body" element, so any other event
that prevent events from bubbling will not emit this to the WebSocket
resource.

=head1 SYNOPSIS

=head2 Application

  use Mojolicious::Lite;
  plugin "surveil";

=head2 In your browser

Visit L<http://localhost:3000?_surveil=1> to enable the logging. Try clicking
around on your page and look in the console for log messages.

=head1 METHODS

=head2 register

  $self->register($app, \%config);

Used to add an "after_render" hook into the application which adds a
JavaScript to every HTML document when the L</enable_param> is set.

C<%config> can have the following settings:

=over 2

=item * enable_param

Used to specify a query parameter to be part of the URL to enable surveil.

Default is "_surveil".

=item * events

The events that should be reported back over the WebSocket.

Defaults to blur, click, focus, touchstart, touchcancel and touchend.

Note that the default list might change in the future.

=item * path

The path to the WebSocket route.

Defaults to C</mojolicious/plugin/surveil>.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2018, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

__DATA__
@@ mojolicious/plugin/surveil.html.ep
<script type="text/javascript">
(function(w) {
  var events = <%== $events %>;
  var socket = new WebSocket("<%= $surveil_url %>");
  var console = w.console;

  console.surveil = function() {
    socket.send(JSON.stringify({type: "console", target: "window", message: Array.prototype.slice.call(arguments)}));
  };

  socket.onopen = function() {
    socket.send(JSON.stringify({type: "load", target: "window"}));
    for (i = 0; i < events.length; i++) {
      document.body.addEventListener(events[i], function(e) {
        var data = { extra: {} };
        for (var prop in e) {
          if (!(typeof e[prop]).match(/^(boolean|number|string)$/)) continue;
          if (prop.match(/^[A-Z]/)) continue;
          data[prop] = e[prop];
        }
        data.target = [e.target.tagName.toLowerCase(), e.target.id ? "#" + e.target.id : "", e.target.className ? "." + e.target.className.replace(/ /g, ".") : ""].join("");
        if (data.target.href) data.extra.href = "" + data.target.href;
        socket.send(JSON.stringify(data));
      });
    }
  }
})(window);
</script>
