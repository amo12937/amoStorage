"use strict"

angular.module("amo.webStorage", []).provider "amoStorage", ->
  _appPrefix = "amoStorage"
  _separator = "."

  WebStorage = (_webStorage, _prefix) ->
    _genKey = (key) -> [_appPrefix, _prefix, key].join(_separator)
    storage =
      get: (key, defaultValue = null) ->
        angular.fromJson(_webStorage.getItem(_genKey(key))) or defaultValue
      set: (key, value) ->
        _webStorage.setItem(_genKey(key), angular.toJson(value))

    return storage

  return {
    setAppPrefix: (prefix) ->
      _appPrefix = prefix
      return @
    getAppPrefix: -> _appPrefix

    setSeparator: (separator) ->
      _separator = separator
      return @
    getSeparator: -> _separator

    $get: ->
      _storages =
        local: {}
        session: {}

      return {
        getAppPrefix: -> _appPrefix
        getSeparator: -> _separator
        getLocalStorage: (prefix = "") ->
          return _storages.local[prefix] ?= WebStorage(localStorage, prefix)
        getSessionStorage: (prefix = "") ->
          return _storages.session[prefix] ?= WebStorage(sessionStorage, prefix)
      }

  }