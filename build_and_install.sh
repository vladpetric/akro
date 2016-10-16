#!/bin/bash
umask 0022 # so that the installed gem is readable by everyone
/usr/bin/gem build akro.gemspec && sudo /usr/bin/gem install akro-0.0.5.gem
