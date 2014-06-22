"use strict"

angular.module("amo.webStorage", []).provider "amoStorageManager", ->
  provider =
    appName: "amoStorage"
    revision: "1.0.0"
    separator: "/"
    keyGeneratorFactory: (appName, revision, separator, prefix) ->
      _prefix = [appName, revision, prefix].join separator
      return (key) -> [_prefix, key].join separator
    ruleForDeletingRevisions: (revision) -> true

    $get: ["$rootScope", ($rootScope) ->
      _appName = provider.appName
      _revision = provider.revision
      _separator = provider.separator
      _keyGeneratorFactory = provider.keyGeneratorFactory
      _ruleForDeletingRevisions = provider.ruleForDeletingRevisions

      _suffix = "#"       # unalterable
      _suffixForSys = "$" # unalterable

      _genKeysKey = (revision) -> "#{_appName}/#{revision}/keys#{_suffixForSys}"
      _keysKey = _genKeysKey _revision
      _revisionsKey = "#{_appName}/revisions#{_suffixForSys}"

      _deleteRevision = (webStorage, revision) ->
        keysKey = _genKeysKey revision
        keys = angular.fromJson webStorage.getItem keysKey
        for key in keys
          webStorage.removeItem key
        webStorage.removeItem keysKey

      _refreshRevisions = (webStorage = localStorage) ->
        revisions = angular.fromJson(webStorage.getItem(_revisionsKey) or "[]")
        newRevisions = [_revision]
        for revision in revisions
          if _revision is revision
            continue
          if _ruleForDeletingRevisions(revision)
            _deleteRevision(webStorage, revision)
          else
            newRevisions.push revision
        webStorage.setItem _revisionsKey, angular.toJson newRevisions

      AmoStorage = (webStorage, prefix, keys) ->
        _genKeyOrg = _keyGeneratorFactory _appName, _revision, _separator, prefix
        _genKey = (key) -> "#{_genKeyOrg(key)}#{_suffix}"

        _confKey =
          EXPIRED_TIME: "e"
          CREATE_DATETIME: "c"
          LAST_USAGE_DATETIME: "u"

        _getSavedValue = (key, now) ->
          if not keys[key]
            return null
          savedValue = angular.fromJson webStorage.getItem(key)
          if now - savedValue.config[_confKey.LAST_USAGE_DATETIME] > savedValue.config[_confKey.EXPIRED_TIME] * 1000
            webStorage.removeItem key
            delete keys[key]
            return null
          return savedValue

        storage =
          confKey: _confKey
          get: (key, defaultValue = null, now = (new Date()).getTime()) ->
            key = _genKey(key)
            savedValue = _getSavedValue key, now
            if not savedValue
              return defaultValue
            return savedValue.value

          use: (key, defaultValue = null, now = (new Date()).getTime()) ->
            key = _genKey(key)
            savedValue = _getSavedValue key, now
            if not savedValue
              return defaultValue
            savedValue.config[_confKey.LAST_USAGE_DATETIME] = now
            webStorage.setItem key, angular.toJson(savedValue)
            return savedValue.value

          set: (key, value, expiredTime, now = (new Date()).getTime()) ->
            key = _genKey(key)
            savedValue = if keys[key] then angular.fromJson webStorage.getItem(key) else
              config: {}
              value: value
            if expiredTime
              savedValue.config[_confKey.EXPIRED_TIME] = expiredTime
            savedValue.config[_confKey.CREATE_DATETIME] ?= now
            savedValue.config[_confKey.LAST_USAGE_DATETIME] = now
            webStorage.setItem key, angular.toJson(savedValue)
            keys[key] = true
            return @

          del: (key) ->
            value = @get key
            key = _genKey(key)
            webStorage.removeItem key
            delete keys[key]
            return value

        return storage

      storageFactory = (webStorage) ->
        _refreshRevisions(webStorage)
        _storages = {}
        _keys = angular.fromJson(webStorage.getItem(_keysKey) or "{}")
        _prevKeys = {}
        for k of _keys
          _prevKeys[k] = true

        _debounce = null
        $rootScope.$watch ->
          _debounce or (_debounce = setTimeout((->
            _debounce = null
            _oldKeys = _prevKeys
            _prevKeys = {}
            b = false
            for k of _keys
              _prevKeys[k] = true
              b or= (not _oldKeys[k])
              delete _oldKeys[k]
            for _ of _oldKeys
              b = true
              break;
            if b
              webStorage.setItem _keysKey, angular.toJson(_prevKeys)
          ), 100))

        return (prefix) ->
          _storages[prefix] ?= AmoStorage(webStorage, prefix, _keys)

      return {
        getLocalStorage: storageFactory(localStorage)
        getSessionStorage: storageFactory(sessionStorage)
      }
    ]
  return provider
