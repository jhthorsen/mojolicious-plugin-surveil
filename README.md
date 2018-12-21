# NAME

Mojolicious::Plugin::Surveil - Surveil user actions

# VERSION

0.02

# DESCRIPTION

[Mojolicious::Plugin::Surveil](https://metacpan.org/pod/Mojolicious::Plugin::Surveil) is a plugin which allow you to see every
event a user trigger on your web page. It is meant as a debug tool for
seeing events, even if the browser does not have a JavaScript console.

CAVEAT: The JavaScript that is injected require WebSocket in the browser to
run. The surveil events are attached to the "body" element, so any other event
that prevent events from bubbling will not emit this to the WebSocket
resource.

# SYNOPSIS

## Application

    use Mojolicious::Lite;
    plugin "surveil";

## In your browser

Visit [http://localhost:3000?\_surveil=1](http://localhost:3000?_surveil=1) to enable the logging. Try clicking
around on your page and look in the console for log messages.

# METHODS

## register

    $self->register($app, \%config);

Used to add an "after\_render" hook into the application which adds a
JavaScript to every HTML document when the ["enable\_param"](#enable_param) is set.

`%config` can have the following settings:

- enable\_param

    Used to specify a query parameter to be part of the URL to enable surveil.

    Default is "\_surveil".

- events

    The events that should be reported back over the WebSocket.

    Defaults to blur, click, focus, touchstart, touchcancel and touchend.

    Note that the default list might change in the future.

- path

    The path to the WebSocket route.

    Defaults to `/mojolicious/plugin/surveil`.

# COPYRIGHT AND LICENSE

Copyright (C) 2014-2018, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# AUTHOR

Jan Henning Thorsen - `jhthorsen@cpan.org`
