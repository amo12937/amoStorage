"use strict"

util = {}
util.isEmptyObj = (obj) ->
  for _ of obj
    return false
  return true

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

      _genKeysListKey = (revision) -> "#{_appName}/#{revision}/keys#{_suffixForSys}"
      _keysListKey = _genKeysListKey _revision
      _revisionsKey = "#{_appName}/revisions#{_suffixForSys}"

      _deleteRevision = (webStorage, revision) ->
        keysListKey = _genKeysListKey revision
        keysList = angular.fromJson webStorage.getItem keysListKey
        for p, keys of keysList
          for key of keys
            webStorage.removeItem key
        webStorage.removeItem keysListKey

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
          if not keys.get key
            return null
          savedValue = angular.fromJson webStorage.getItem(key)
          if not savedValue
            return null
          if now - savedValue.config[_confKey.LAST_USAGE_DATETIME] > savedValue.config[_confKey.EXPIRED_TIME] * 1000
            webStorage.removeItem key
            keys.del key
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
            savedValue = angular.fromJson webStorage.getItem(key)
            if not (savedValue and savedValue.config and savedValue.value)
              savedValue =
                config: {}
            savedValue.value = value
            if expiredTime
              savedValue.config[_confKey.EXPIRED_TIME] = expiredTime
            savedValue.config[_confKey.CREATE_DATETIME] ?= now
            savedValue.config[_confKey.LAST_USAGE_DATETIME] = now
            webStorage.setItem key, angular.toJson(savedValue)
            keys.set key
            return @

          del: (key) ->
            value = @get key
            key = _genKey(key)
            webStorage.removeItem key
            keys.del key
            return value

          delAll: ->
            keys.delAll()

        return storage

      storageFactory = (webStorage) ->
        _refreshRevisions(webStorage)
        _storages = {}
        _keysList = angular.fromJson(webStorage.getItem(_keysListKey) or "{}")
        Keys = (prefix) ->
          _keys = _keysList[prefix] ?= {}
          self =
            get: (key) -> _keys[key] or false
            set: (key) ->
              _keys[key] = true
              webStorage.setItem _keysListKey, angular.toJson _keysList
              return self
            del: (key) ->
              delete _keys[key]
              webStorage.setItem _keysListKey, angular.toJson _keysList
            delAll: ->
              for k of _keys
                webStorage.removeItem k
                delete  _keys[k]
              webStorage.setItem _keysListKey, angular.toJson _keysList
          return self

#        _prevKeys = {}
#        for p, v of _keysList
#          _prevKeys[p] = {}
#          for k of v
#            _prevKeys[p][k] = true
#
#        _debounce = null
#        $rootScope.$watch ->
#          _debounce or (_debounce = setTimeout((->
#            _debounce = null
#            _oldKeys = _prevKeys
#            _prevKeys = {}
#            b = false
#            for p, v of _keysList
#              _prevKeys[p] = {}
#              for k of v
#                _prevKeys[p][k] = true
#                b or= (not _oldKeys[p]?[k])
#                delete _oldKeys[p]?[k]
#              b or= not util.isEmptyObj _oldKeys[p]
#            if b
#              webStorage.setItem _keysListKey, angular.toJson(_prevKeys)
#          ), 100))

        return (prefix) ->
          _storages[prefix] ?= AmoStorage(webStorage, prefix, Keys(prefix))

      return {
        getLocalStorage: storageFactory(localStorage)
        getSessionStorage: storageFactory(sessionStorage)
      }
    ]
  return provider
