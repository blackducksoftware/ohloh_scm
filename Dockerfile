FROM ubuntu:22.04
MAINTAINER OpenHub <info@openhub.net>

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home
ENV PATH $HOME/.rbenv/shims:$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH

RUN apt-get update
RUN apt-get install -y build-essential software-properties-common locales ragel \
  libxml2-dev libpcre3 libpcre3-dev swig gperf openssh-server expect libreadline-dev \
  zlib1g-dev git git-svn subversion cvs mercurial bzr ca-certificates

RUN locale-gen en_US.UTF-8

RUN cd $HOME \
  && git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv \
  && git clone https://github.com/sstephenson/ruby-build.git $HOME/.rbenv/plugins/ruby-build \
  && echo 'eval "$(rbenv init -)"' >> $HOME/.bashrc \
  && echo 'gem: --no-rdoc --no-ri' >> $HOME/.gemrc \
  && echo 'export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:/home/.rbenv/plugins/ruby-build/bin:$PATH"' >> $HOME/.bash_profile \
  && rbenv install 2.6.9 && rbenv global 2.6.9

RUN git config --global --add safe.directory '*'

RUN ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
RUN echo 'StrictHostKeyChecking no' >> /root/.ssh/config

RUN mkdir -p ~/.bazaar/plugins
RUN cd ~/.bazaar/plugins
RUN bzr branch lp:bzr-xmloutput ~/.bazaar/plugins/xmloutput

RUN ln -s /usr/bin/cvs /usr/bin/cvsnt

RUN gem update --system
RUN gem install rake
RUN gem install bundler -v '~> 1.17'

RUN mkdir -p /home/app/ohloh_scm
WORKDIR /home/app/ohloh_scm
ADD . /home/app/ohloh_scm

RUN bundle config --global silence_root_warning 1
RUN bundle install
