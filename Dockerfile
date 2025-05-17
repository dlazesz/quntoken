# From official Ubuntu 18.04 LTS Bionic image pinned by its name bionic (last to have g++-5)
FROM ubuntu:bionic

## Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        make \
        python \
        gcc \
        g++-5 \
        wget \
        ca-certificates \
        python3-dev \
        python3-venv && \
	apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Build noske components
COPY . /build/
WORKDIR /build/

RUN make prereq release

CMD ["sh", "-c", "cp /build/dist/quntoken-*-py3-none-any.whl /build/release/"]
