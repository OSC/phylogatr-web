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

# install Ruby
RUN dnf -y module install ruby:2.5
RUN dnf -y install ruby-devel \
    && dnf clean all && rm -rf /var/cache/dnf/*
RUN gem install bundler:1.17.3

# install Python pipeline dependencies
RUN dnf -y install python3
RUN pip3 install biopython
RUN pip3 install invoke

# install mafft, trimal, and seqkit
# RUN mkdir -p /src
# COPY docker/aligntools-setup.sh /src/aligntools-setup.sh
# RUN /src/aligntools-setup.sh

RUN mkdir -p /src
RUN curl -o /src/trimal.tar.gz http://trimal.cgenomics.org/_media/trimal.v1.2rev59.tar.gz
RUN cd /src && tar xzf trimal.tar.gz && cd trimAl/source && make && cp trimal readal /usr/local/bin

RUN curl -o /src/mafft.tar.gz https://mafft.cbrc.jp/alignment/software/mafft-7.475-with-extensions-src.tgz
RUN cd /src && tar xzf mafft.tar.gz && cd mafft-7.475-with-extensions/core && make clean && make && make install

RUN cd /src && curl -LJO https://github.com/shenwei356/seqkit/releases/download/v0.16.0/seqkit_linux_amd64.tar.gz
RUN cd /src && tar xzf seqkit_linux_amd64.tar.gz && cp seqkit /usr/local/bin

COPY . /app
RUN cd /app && bin/bundle install
RUN cd /app && bin/rake assets:precompile

WORKDIR /app
CMD bundle exec passenger start
