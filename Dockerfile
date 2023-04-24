FROM ubuntu:22.04
MAINTAINER OpenHub <info@openhub.net>

ENV HOME /home
ENV LC_ALL en_US.UTF-8
ENV APP_HOME $HOME/app/ohloh_scm
ENV DEBIAN_FRONTEND noninteractive
ENV PATH $HOME/.rbenv/shims:$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH

RUN apt-get update
RUN apt-get install -y build-essential software-properties-common locales ragel \
  libxml2-dev libpcre3 libpcre3-dev swig gperf openssh-server expect libreadline-dev \
  zlib1g-dev git git-svn subversion cvs ca-certificates

RUN apt-get install -y python2.7 python2-dev python-pip \
  && ln -s /usr/bin/python2.7 /usr/local/bin/python
RUN pip2 install bzr "mercurial==4.5.3"

RUN locale-gen en_US.UTF-8

RUN cd $HOME \
  && git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv \
  && git clone https://github.com/sstephenson/ruby-build.git $HOME/.rbenv/plugins/ruby-build \
  && echo 'eval "$(rbenv init -)"' >> $HOME/.bashrc \
  && echo 'gem: --no-rdoc --no-ri' >> $HOME/.gemrc \
  && echo 'export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:/home/.rbenv/plugins/ruby-build/bin:$PATH"' >> $HOME/.bash_profile \
  && rbenv install 2.6.9 && rbenv global 2.6.9

RUN git config --global --add safe.directory '*'

RUN ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa \
  && cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys \
  && echo 'StrictHostKeyChecking no' >> /root/.ssh/config

RUN mkdir -p ~/.bazaar/plugins \
  && cd ~/.bazaar/plugins \
  && bzr branch lp:bzr-xmloutput ~/.bazaar/plugins/xmloutput

RUN ln -s /usr/bin/cvs /usr/bin/cvsnt

# Run bundle install before copying source to keep this step cached.
RUN mkdir -p $APP_HOME
COPY Gemfile* $APP_HOME/
RUN gem install rake bundler:1.17.3 \
  && bundle config --global silence_root_warning 1 \
  && cd $APP_HOME && bundle install

ADD . $APP_HOME
WORKDIR $APP_HOME
