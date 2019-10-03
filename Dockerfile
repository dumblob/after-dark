#
# Copyright (C) 2019  Josh Habdas <jhabdas@protonmail.com>
#
# This file is part of After Dark.
#
# After Dark is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# After Dark is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# DOCKER-VERSION 19.03.1-ce, build 74b1e89e8a

# Specify build image
ARG GO_VERSION=1.11.4
ARG BUILD_TARGET=alpine3.8

# Pull builder base image
FROM golang:${GO_VERSION}-${BUILD_TARGET} AS hugobuilder

# Set hugo environment variables
ENV HUGO_VERSION=0.57.0 \
    CGO_ENABLED=1 \
    GOOS=linux \
    GO111MODULE=on \
    BUILD_TAGS="extended"

# Build hugo from source using specified version
RUN \
  apk add --update --no-cache git gcc g++ binutils musl-dev && \
  git clone https://github.com/gohugoio/hugo.git $GOPATH/src/github.com/gohugoio/hugo && \
  cd ${GOPATH:-$HOME/go}/src/github.com/gohugoio/hugo && \
  git checkout v$HUGO_VERSION && \
  go install -ldflags '-s -w -extldflags "-static"' -tags ${BUILD_TAGS}

# Install After Dark via script
FROM node:alpine as sitebuilder
COPY --from=hugobuilder /go/bin/hugo /usr/local/bin/hugo
WORKDIR /tmp
RUN wget -qO - https://go.habd.as/after-dark | sh

# Move compiled sources into micro container
FROM busybox
EXPOSE 80
COPY --from=hugobuilder /go/bin/hugo /usr/local/bin/hugo
COPY --from=sitebuilder /tmp/flying-toasters/ /opt/after-dark/
ENTRYPOINT ["/usr/local/bin/hugo"]
CMD ["serve","--buildDrafts","--bind","0.0.0.0","--port","80","--source","/opt/after-dark","--destination","/var/www"]