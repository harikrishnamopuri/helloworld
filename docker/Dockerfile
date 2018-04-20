# OcNOS build environment
FROM debian:8.2

# Create source list - Update sources.list to pull from 8.2 snapshot
RUN echo deb  http://deb.debian.org/debian jessie main > /etc/apt/sources.list
RUN sed -e 's@deb @deb-src @g' /etc/apt/sources.list > /etc/apt/sources.list.d/sources.list

# Update, install and do cleanup
RUN apt-get -y   update && \
        apt-get -y   build-dep linux && \
        apt-get -y   install \
          autoconf \
          automake \
          binfmt-support \
          bison \
          build-essential \
          debootstrap \
          emacs \
          fakeroot \
          flex \
          python-dev \
          python-libxml2 \
          python-lxml \
          python-netsnmp \
          python-pip \
          sudo \
          tar \
          uucp \
          vim \
          wget && \
        apt-get -y clean all  

# Install virtualenv and lxml python packages
RUN pip install virtualenv --upgrade
RUN pip install lxml

# Create build user, assign password and give sudo rights
RUN useradd -Gsudo -m test
RUN echo "test:ChangeMe" | chpasswd
RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/sudo

# Pull and build cxfreeze that actually works correctly without any games
VOLUME [/test]
WORKDIR /test

CMD ["/bin/bash"]
