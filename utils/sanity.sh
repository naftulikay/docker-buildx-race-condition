#!/usr/bin/env sh

_log() {
    echo '***' "$@" >&2
}

_error() {
    _log "ERROR:" "$@"
}

_fatal() {
    _error "$@"
    exit 1
}

COUNT=$(find ./node_modules -mindepth 1 -maxdepth 1 | wc -l)

if [ "$COUNT" = "0" ]; then
    _fatal "node modules were not copied over, directory empty"
fi

if [ ! -e "./index.js" ]; then
    _fatal "index.js was not copied over, file does not exist"
fi

if [ "${1:-}" = "--clean" ]; then
    _log 'my work here is done'
    rm -f "${0}"
fi