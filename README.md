[![Ohloh SCM on OpenHub](https://www.openhub.net/p/ohloh_scm/widgets/project_partner_badge.gif)](https://www.openhub.net/p/ohloh_scm)
![Coverity Scan Build](https://github.com/blackducksoftware/ohloh_scm/actions/workflows/coverity.yml/badge.svg?branch=main)
![Build Status](https://github.com/blackducksoftware/ohloh_scm/actions/workflows/ci.yml/badge.svg?branch=main)

# Ohloh SCM

The OpenHub source control management library

## Overview

Ohloh SCM is an abstraction layer for source control management systems,
allowing an application to interoperate with various SCMs using a
single interface.

It was originally developed at OpenHub, and is used to generate
the reports at www.openhub.net.

## Using Docker

One may use Docker to run Ohloh SCM and test changes.

```sh
$ git clone https://github.com/blackducksoftware/ohloh_scm
$ cd ohloh_scm
$ docker build -t ohloh_scm:foobar .

# To run all tests, we need to start the ssh server and set UTF-8 locale for encoding tests.
$ cmd='/etc/init.d/ssh start; LANG=en_US.UTF-8 rake test 2> /dev/null'
$ docker run --rm -P -v $(pwd):/home/app/ohloh_scm -ti ohloh_scm:foobar /bin/sh -c "$cmd"
# This mounts the current folder into the docker container;
#   hence any edits made in ohloh_scm on the host machine would reflect in the container.
```

## Development Setup

Besides docker, one could setup OhlohScm locally on Ubuntu with the following commands:

```sh
sudo apt-get update
sudo apt-get install -y build-essential software-properties-common

sudo apt-add-repository -y ppa:brightbox/ruby-ng
sudo apt-get update
sudo apt-get install -y ruby2.5 ruby2.5-dev

sudo apt-get install -y ragel libxml2-dev libpcre3 libpcre3-dev swig gperf
sudo apt-get install -y git git-svn subversion cvs mercurial bzr
sudo ln -s /usr/bin/cvs /usr/bin/cvsnt

mkdir -p ~/.bazaar/plugins
cd ~/.bazaar/plugins
bzr branch lp:bzr-xmloutput ~/.bazaar/plugins/xmloutput

gem install bundler
bundle install

# For running tests
sudo apt-get install -y openssh-server expect locales
sudo locale-gen en_US.UTF-8
```

OhlohScm is currently tested on the following versions:
Git 2.17.1, SVN 1.9.7, CVSNT 2.5.04, Mercurial 4.5.3 and Bazaar 2.8.0

OhlohScm has been tested with other linux distros and MacOSx. The installation instructions will differ.
Let us know if you need help installing OhlohScm on other distros.

## Running tests

```sh
$ rake test
$ ./bin/run-test spec/ohloh_scm/version_spec.rb foobar # run a single test matching 'foobar' # Used as /.*foobar.*/.
$ ./bin/run-tests version_spec.rb foobar_spec.rb      # run multiple tests.
```

## Auto check for rubocop compliance and test failures

This will prevent a git commit if the files being committed fail rubocop or their related tests.
```sh
$ git config core.hooksPath .git_hooks/
```
```sh
# Skip hooks when committing temporary code that breaks rubocop/tests.
$ git commit -m 'temp' --no-verify
```

## Contact OpenHub

You can reach OpenHub via email at:
[info@openhub.net](mailto:info@openhub.net)
