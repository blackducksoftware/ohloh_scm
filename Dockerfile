FROM ubuntu:18.04
MAINTAINER OpenHub <info@openhub.net>

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y build-essential software-properties-common locales
RUN locale-gen en_US.UTF-8

RUN apt-add-repository -y ppa:brightbox/ruby-ng
RUN apt-get update
RUN apt-get install -y ruby2.5 ruby2.5-dev

RUN apt-get install -y ragel libxml2-dev libpcre3 libpcre3-dev swig gperf openssh-server expect
RUN apt-get install -y git git-svn subversion cvs mercurial bzr
RUN git config --global --add safe.directory '*'

RUN ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa
RUN cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
RUN echo 'StrictHostKeyChecking no' >> ~/.ssh/config

RUN mkdir -p ~/.bazaar/plugins
RUN cd ~/.bazaar/plugins
RUN bzr branch lp:bzr-xmloutput ~/.bazaar/plugins/xmloutput

RUN ln -s /usr/bin/cvs /usr/bin/cvsnt

RUN gem install rake
RUN gem install bundler -v '~> 1.17'

RUN mkdir -p /home/app/ohloh_scm
WORKDIR /home/app/ohloh_scm
ADD . /home/app/ohloh_scm

RUN bundle config --global silence_root_warning 1
RUN bundle install
