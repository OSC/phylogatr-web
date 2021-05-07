FROM centos:8
LABEL maintainer 'Eric Franz <efranz@osc.edu>'
RUN dnf update -y && dnf clean all && rm -rf /var/cache/dnf/*
RUN dnf install -y \
        dnf-utils \
        epel-release \
    && dnf config-manager --set-enabled powertools \
    && dnf clean all && rm -rf /var/cache/dnf/*

RUN dnf install -y \
        gcc gcc-c++ gdb make curl curl-devel openssl-devel libxml2-devel \
        sqlite-devel \
        readline-devel \
        redhat-rpm-config \
        shared-mime-info \
        mariadb-devel \
        nodejs \
    && dnf clean all && rm -rf /var/cache/dnf/*

#RUN mkdir -p /opt/phylogatr
#COPY docker/passenger-setup.sh /opt/phylogatr/passenger-setup.sh
#RUN /opt/phylogatr/passenger-setup.sh
RUN dnf -y module install ruby:2.5
RUN dnf -y install ruby-devel \
    && dnf clean all && rm -rf /var/cache/dnf/*
RUN gem install bundler:1.17.3

COPY . /app
RUN cd /app && bin/bundle install
RUN cd /app && bin/rake assets:precompile

WORKDIR /app
CMD bundle exec passenger start
