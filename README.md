# Blink1 Mumble Plugin

This is a very simple plugin that sets the LED to green when you are silent 
and to blue when you are talking.

Note: this was primarly made to test the new ImportC functionality in D.

## Building
Make sure to have [the blink1 library](https://github.com/todbot/blink1-tool/) installed, 
then simply run `dub build`. The resulting library can be installed in Mumble 1.4.0 or later via 
_Configure -> Settings -> Plugins -> Install plugin..._. Mumble versions before 1.4.0 are 
not supported.
