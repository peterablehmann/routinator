# -- stage 1: build static routinator with musl libc for alpine
FROM rust:1.30.1-stretch as build

RUN apt-get -yq update && \
    apt-get -yq install musl-tools

RUN rustup target add x86_64-unknown-linux-musl

WORKDIR /tmp/routinator
COPY . .

RUN cargo build --target=x86_64-unknown-linux-musl --release --locked

# -- stage 2: create alpine-based container with the static routinator executable
FROM alpine:3.8
COPY --from=build /tmp/routinator/target/x86_64-unknown-linux-musl/release/routinator /usr/local/bin/

# Install rsync as routinator depends on it
RUN apk add rsync

# Due to ARIN TAL distribution terms, we can't do this here. An individual user, however,
# might want to anyway - after reviewing https://www.arin.net/resources/rpki/tal.html
# If this is in place, mouting a volume at run time with this file is no longer necessary.
# 
# ADD https://www.arin.net/resources/rpki/arin-rfc7730.tal /root/.rpki-cache/tals/arin.tal

VOLUME ["/root/.rpki-cache"]
EXPOSE 3323/tcp
CMD ["routinator","-r","-l","0.0.0.0:3323"]
