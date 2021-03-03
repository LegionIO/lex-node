FROM legionio/legion:latest
LABEL maintainer="Matthew Iverson <matthewdiverson@gmail.com>"

RUN mkdir /etc/legionio
RUN apk update && apk add build-base tzdata gcc git

COPY . ./
RUN gem install lex-elastic_app_search --no-document --no-prerelease
CMD ruby --jit $(which legionio)
