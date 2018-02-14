[![Ohloh SCM on Ohloh](https://www.ohloh.net/p/ohloh_scm/widgets/project_partner_badge.gif)](https://www.ohloh.net/p/ohloh_scm) [![Build Status](https://travis-ci.org/blackducksoftware/ohloh_scm.svg?branch=master)](https://travis-ci.org/blackducksoftware/ohloh_scm)

# Ohloh SCM

The Ohloh source control management library

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License Version 2 as
published by the Free Software Foundation.

Ohcount is specifically licensed under GPL v2.0, and no later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Overview

Ohloh SCM is an abstraction layer for source control management systems,
allowing an application to interoperate with various SCMs using a
single interface.

It was originally developed at Ohloh, and is used to generate
the reports at www.ohloh.net.

## System Requirements

Ohloh SCM is developed on Mac OS X 10.5 and Ubuntu 6.06 LTS. Other Linux
environments should also work, but your mileage may vary.

Ohloh SCM does not support Windows.

Ohloh SCM targets Ruby 1.8.6 and Rake 0.8.1

Ohloh SCM interfaces with CVSNT, Subversion, Git and Mercurial through the
shell.  In order to pass the unit tests, all three systems must be installed
and on your path. Ohloh uses the following versions, and other versions are
totally unsupported at this time:

cvsnt 2.5.03  
svn 1.4.2  
git 1.8.2.1  
hg 1.1.2  

If you are using CVS instead of CVSNT, you can potentially try creating
a shell alias or symlink mapping 'cvsnt' to 'cvs'.

Ohloh SCM uses [posix-spawn](https://github.com/rtomayko/posix-spawn) to
execute commands so ensure *posix-spawn* gem is installed

``gem install posix-spawn``


## Usage with Bundler

```
gem 'ohloh_scm', git: 'https://github.com/blackducksw/ohloh_scm/', require: 'scm'
gem 'posix-spawn'
```
## Running

Ensure that cvsnt, svn, svnadmin, svnsync, git, and hg are all on your path. You'll also need to ensure that you have the xmloutput plugin installed for bazaar.

### Installing The XmlOutput Plugin
    $ cd ~
    $ mkdir .bazaar
    $ cd .bazaar
    $ mkdir plugins
    $ cd plugins

Now checkout the latest version of the xmloutput plugin (0.8.8 as of 11/21/2011). 

    $ bzr branch lp:~amujumdar/bzr-xmloutput/emit_authors

The default checkout directory is poorly named and bazaar will complain about this unless it is renamed.

    $ mv emit_authors xmloutput

Now you just need to install the xmloutput plugin

    $ cd xmloutput
    $ python setup.py build_ext -i

Verify that the plugin was installed correctly

    $ bzr plugins

You should see some text like "xmloutput 0.8.8"

Then you can run the unit tests:

    $ rake

You can load the library into your own Ruby application by requiring lib/ohloh_scm.rb.

# Functionality

For each tracked repository, Ohloh uses the SCM library to maintain a private
local mirror. The SCM library hides the differences between source control
systems. The SCM library manages all required updates to a mirror, and reports
the contents of the mirror in standardized ways.

Each mirror is assigned a dedicated directory, and the SCM library adapter may
store any content it desires in that directory. Usually, it's a direct clone of
the original repository, but in the case of CVS or some Subversion servers, it
is a conversion of the original repository to Git.

The main Ohloh application orchestrates the scheduling of all updates and
backups. On demand, the SCM library adapter then performs the following basic
tasks on the local mirror:

1. Pull changes -- From a remote repository URL, pull any changes to the local
mirror. This step may involve conversion from one system to another.
2. Push changes -- From the local mirror, push any changes to another Ohloh
server. This is required to create backup copies and perform load balancing on
the Ohloh cluster, and typically occurs over ssh.
3. Commit log -- Given the last known commit, report the list of new commits,
if any, including their diffs.
4. Cat file or parent -- Given a commit, return either the contents of a
single file, or that file's previous contents.
5. Export tree -- Given a commit, export the entire contents of the source tree
to a specified temp directory.

The adapter must also implement validation routines used to filter user inputs
and confirm the presence of the remote server.

# Contact Ohloh

For more information visit the Ohloh website:
[Ohloh Labs](http://labs.ohloh.net)

You can reach Ohloh via email at:
[info@ohloh.net](mailto:info@ohloh.net)

