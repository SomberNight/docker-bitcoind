FROM debian:trixie

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

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
		python3 \
		git \
		cmake \
		pkgconf \
		libevent-dev \
		libboost-dev \
		libsqlite3-dev \
		libzmq3-dev \
		gosu \
		tor \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "ControlPort 9051" >> /etc/tor/torrc && \
	echo "CookieAuthentication 1" >> /etc/tor/torrc && \
	echo "RunAsDaemon 1" >> /etc/tor/torrc

# tag "v30.0"
ENV BITCOIN_VERSION d0f6d9953a15d7c7111d46dcb76ab2bb18e5dee3
RUN cd /opt && \
	git clone https://github.com/bitcoin/bitcoin.git && \
	cd bitcoin/ && \
	git checkout "${BITCOIN_VERSION}^{commit}" && \
	cmake -B build \
		-DENABLE_WALLET=OFF \
		-DBUILD_GUI=OFF \
		-DWITH_ZMQ=ON \
		-DBUILD_TESTS=OFF \
		-DENABLE_IPC=OFF \
		&& \
	cmake --build build "-j$(nproc)" && \
	cmake --install build

ADD ./bin /usr/local/bin

VOLUME ["/bitcoin"]

EXPOSE 8332 8333 18332 18333

WORKDIR /bitcoin

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["btc_oneshot"]
