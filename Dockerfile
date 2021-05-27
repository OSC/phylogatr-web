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
        libnsl \
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

# Add SLURM
RUN dnf config-manager --add-repo https://repo.hpc.osc.edu/internal/slurm/slurm.repo
RUN dnf config-manager --add-repo https://repo.hpc.osc.edu/internal/osc_yum_repo/osc_repo.repo
RUN dnf -y install slurm slurm-spank-lua lua lua-posix \
    && dnf clean all && rm -rf /var/cache/dnf/*
RUN groupadd -r slurm
RUN useradd -r -g slurm -d /var/spool/slurm -s /sbin/nologin slurm

# Add gem deps that require building native extensions
RUN gem install byebug -v 11.1.3
RUN gem install debug_inspector -v 1.1.0
RUN gem install ffi -v 1.15.1
RUN gem install mimemagic -v 0.3.10
RUN gem install mysql2 -v 0.4.10
RUN gem install nokogiri -v 1.11.5
RUN gem install passenger -v 6.0.8
RUN gem install racc -v 1.5.2
RUN gem install redcarpet -v 3.5.1
RUN gem install sassc -v 2.4.0
RUN gem install sqlite3 -v 1.3.13
RUN gem install jquery-rails -v 4.4.0

# Copy app and install rest of the gems
COPY . /app
RUN cd /app && bin/bundle install
RUN cd /app && bin/rake assets:precompile

RUN groupadd -g 6314 PAS1604
RUN groupadd -g 6557 accessphylogatr
RUN groupadd -g 6558 accessphylogatrdev
RUN useradd -g PAS1604 -u 33252 -d /users/PAS1604/phylogatr -M phylogatr
RUN useradd -g PAS1604 -u 33253 -d /users/PAS1604/phylogatrdev -M phylogatrdev
RUN usermod -aG accessphylogatr phylogatr
RUN usermod -aG accessphylogatrdev phylogatr
RUN usermod -aG accessphylogatr phylogatrdev
RUN usermod -aG accessphylogatrdev phylogatrdev
RUN chgrp -R PAS1604 /app/log && chmod -R g=u /app/log
RUN chgrp -R PAS1604 /app/tmp && chmod -R g=u /app/tmp

WORKDIR /app
CMD bundle exec passenger start
