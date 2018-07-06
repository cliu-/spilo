#FROM spilo:squashed
FROM spilo-build-demo:0.1

MAINTAINER LeapDevOps <leapdevops@opentext.com>

EXPOSE 5432 8008 8080

ARG DEBUG=false
ENV DEBUG=$DEBUG

ARG DEMO=true
ENV DEMO=$DEMO

ARG WITH_PERL=false
ARG PGVERSION="10"

ENV PGVERSION="$PGVERSION" \
    POSTGIS_VERSION=2.4 \
    BG_MON_COMMIT=78f34bebd51108810ede18c7403f34f90e6be18c \
    DECODERBUFS_COMMIT=e2da72713909d4315aa63f46819412ec4f9f6a42 \
    SET_USER=REL1_6_0 \
    PLPGSQL_CHECK=v1.2.2 \
    PLPROFILER=REL3_2 \
    TIMESCALEDB=0.9.2 \
    PAM_OAUTH2=v1.0

ENV PATRONIVERSION=1.4.5
ENV WALE_VERSION=1.1.0

ENV LC_ALL=en_US.utf-8 \
    PATH=$PATH:/usr/lib/postgresql/${PGVERSION}/bin \
    PGHOME=/home/postgres

ENV WALE_ENV_DIR=$PGHOME/etc/wal-e.d/env \
    PGROOT=$PGHOME/pgdata/pgroot

ENV PGDATA=$PGROOT/data \
    PGLOG=$PGROOT/pg_log

WORKDIR $PGHOME

ADD motd /etc/
ADD supervisor /etc/supervisor
ADD pgq_ticker.ini $PGHOME/

RUN mkdir -p /var/log/supervisor \
        && ln -s supervisor/supervisord.conf /etc/supervisord.conf \
        && sed -i "s|/var/lib/postgresql.*|$PGHOME:/bin/bash|" /etc/passwd \
        && chown -R postgres:postgres $PGHOME \
        && sed -i 's/set compatible/set nocompatible/' /etc/vim/vimrc.tiny \
        && for e in TERM=linux LC_ALL=C.UTF-8 LANG=C.UTF-8 EDITOR=vi; \
            do echo "export $e" >> /etc/bash.bashrc; \
        done \
        && echo "export PAGER='pspg -bX --no-mouse'" >> /etc/bash.bashrc \
        && echo "source /etc/motd" >> /root/.bashrc

ADD scripts bootstrap /scripts/

ADD scm-source.json launch.sh /

CMD ["/bin/sh", "/launch.sh"]
