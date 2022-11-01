FROM rockylinux/rockylinux:8
LABEL maintainer 'Eric Franz <efranz@osc.edu>'
RUN dnf update -y && dnf clean all && rm -rf /var/cache/dnf/*
RUN dnf install -y \
        dnf-utils \
        epel-release gzip \
    && dnf config-manager --set-enabled powertools \
    && dnf clean all && rm -rf /var/cache/dnf/*

RUN dnf install -y \
        gcc gcc-c++ gdb make curl curl-devel openssl-devel libxml2-devel \
        sqlite-devel readline-devel redhat-rpm-config shared-mime-info \
        mariadb-devel nodejs libnsl procps-ng mariadb \
    && dnf clean all && rm -rf /var/cache/dnf/*

# install Ruby
RUN dnf -y module install ruby:2.7
RUN dnf -y install ruby-devel \
    && dnf clean all && rm -rf /var/cache/dnf/*
RUN gem install bundler:2.1.4

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

# Copy app and install rest of the gems
COPY . /app
RUN cd /app && bin/bundle install
RUN cd /app && bin/rake assets:precompile

RUN groupadd -g 6314 PAS1604
RUN groupadd -g 6557 accessphylogatr
RUN groupadd -g 6558 accessphylogatrdev
RUN mkdir -p /users/PAS1604
RUN useradd -g PAS1604 -u 33252 -d /users/PAS1604/phylogatr -m phylogatr
RUN useradd -g PAS1604 -u 33253 -d /users/PAS1604/phylogatrdev -m phylogatrdev
RUN usermod -aG accessphylogatr phylogatr
RUN usermod -aG accessphylogatrdev phylogatr
RUN usermod -aG accessphylogatr phylogatrdev
RUN usermod -aG accessphylogatrdev phylogatrdev
RUN chgrp -R PAS1604 /app/log && chmod -R g=u /app/log
RUN chgrp -R PAS1604 /app/tmp && chmod -R g=u /app/tmp
RUN chgrp -R PAS1604 /app/db && chmod -R g=u /app/db

WORKDIR /app
CMD bundle exec passenger start
