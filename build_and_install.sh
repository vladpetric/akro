#!/bin/bash
umask 0022 # so that the installed gem is readable by everyone
gem build akro.gemspec && sudo gem install akro-0.0.0.gem
