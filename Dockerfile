FROM ubuntu:18.04

ARG USER_ID
ARG GROUP_ID

ENV HOME /bitcoin

# add user with specified (or default) user/group ids
ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -g ${GROUP_ID} bitcoin \
	&& useradd -u ${USER_ID} -g bitcoin -s /bin/bash -m -d /bitcoin bitcoin

RUN apt-get update && apt-get install -yq \
		build-essential \
		libtool \
		autotools-dev \
		automake \
		pkg-config \
		libssl-dev \
		libevent-dev \
		bsdmainutils \
		python3 \
		libboost-system-dev \
		libboost-filesystem-dev \
		libboost-chrono-dev \
		libboost-program-options-dev \
		libboost-test-dev \
		libboost-thread-dev \
		libzmq3-dev \
		git \
		gosu \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 0.20.1
ENV BITCOIN_VERSION 7ff64311bee570874c4f0dfa18f518552188df08
RUN cd /opt && \
	git clone https://github.com/bitcoin/bitcoin.git && \
	cd bitcoin/ && \
	git checkout ${BITCOIN_VERSION} && \
	./autogen.sh && \
	./configure  --disable-wallet --without-gui --without-miniupnpc --with-zmq --enable-zmq && \
	make -s -j5 && \
	make install

ADD ./bin /usr/local/bin

VOLUME ["/bitcoin"]

EXPOSE 8332 8333 18332 18333

WORKDIR /bitcoin

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["btc_oneshot"]
