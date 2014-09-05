(function() {
  "use strict";
  var util;

  util = {};

  util.isEmptyObj = function(obj) {
    var _;
    for (_ in obj) {
      return false;
    }
    return true;
  };

  angular.module("amo.webStorage", []).provider("amoStorageManager", function() {
    var provider;
    provider = {
      appName: "amoStorage",
      revision: "1.0.0",
      separator: "/",
      keyGeneratorFactory: function(appName, revision, separator, prefix) {
        var _prefix;
        _prefix = [appName, revision, prefix].join(separator);
        return function(key) {
          return [_prefix, key].join(separator);
        };
      },
      ruleForDeletingRevisions: function(revision) {
        return true;
      },
      $get: function() {
        var AmoStorage, storageFactory, _appName, _deleteRevision, _genKeysListKey, _keyGeneratorFactory, _keysListKey, _refreshRevisions, _revision, _revisionsKey, _ruleForDeletingRevisions, _separator, _suffix, _suffixForSys;
        _appName = provider.appName;
        _revision = provider.revision;
        _separator = provider.separator;
        _keyGeneratorFactory = provider.keyGeneratorFactory;
        _ruleForDeletingRevisions = provider.ruleForDeletingRevisions;
        _suffix = "#";
        _suffixForSys = "$";
        _genKeysListKey = function(revision) {
          return "" + _appName + "/" + revision + "/keys" + _suffixForSys;
        };
        _keysListKey = _genKeysListKey(_revision);
        _revisionsKey = "" + _appName + "/revisions" + _suffixForSys;
        _deleteRevision = function(webStorage, revision) {
          var key, keys, keysList, keysListKey, p;
          keysListKey = _genKeysListKey(revision);
          keysList = angular.fromJson(webStorage.getItem(keysListKey));
          for (p in keysList) {
            keys = keysList[p];
            for (key in keys) {
              webStorage.removeItem(key);
            }
          }
          return webStorage.removeItem(keysListKey);
        };
        _refreshRevisions = function(webStorage) {
          var newRevisions, revision, revisions, _i, _len;
          if (webStorage == null) {
            webStorage = localStorage;
          }
          revisions = angular.fromJson(webStorage.getItem(_revisionsKey) || "[]");
          newRevisions = [_revision];
          for (_i = 0, _len = revisions.length; _i < _len; _i++) {
            revision = revisions[_i];
            if (_revision === revision) {
              continue;
            }
            if (_ruleForDeletingRevisions(revision)) {
              _deleteRevision(webStorage, revision);
            } else {
              newRevisions.push(revision);
            }
          }
          return webStorage.setItem(_revisionsKey, angular.toJson(newRevisions));
        };
        AmoStorage = function(webStorage, prefix, keys) {
          var storage, _confKey, _genKey, _genKeyOrg, _getSavedValue;
          _genKeyOrg = _keyGeneratorFactory(_appName, _revision, _separator, prefix);
          _genKey = function(key) {
            return "" + (_genKeyOrg(key)) + _suffix;
          };
          _confKey = {
            EXPIRED_TIME: "e",
            CREATE_DATETIME: "c",
            LAST_USAGE_DATETIME: "u"
          };
          _getSavedValue = function(key, now) {
            var savedValue;
            if (!keys.get(key)) {
              return null;
            }
            savedValue = angular.fromJson(webStorage.getItem(key));
            if (!savedValue) {
              return null;
            }
            if (now - savedValue.config[_confKey.LAST_USAGE_DATETIME] > savedValue.config[_confKey.EXPIRED_TIME] * 1000) {
              webStorage.removeItem(key);
              keys.del(key);
              return null;
            }
            return savedValue;
          };
          storage = {
            confKey: _confKey,
            get: function(key, defaultValue, now) {
              var savedValue;
              if (defaultValue == null) {
                defaultValue = null;
              }
              if (now == null) {
                now = (new Date()).getTime();
              }
              key = _genKey(key);
              savedValue = _getSavedValue(key, now);
              if (!savedValue) {
                return defaultValue;
              }
              return savedValue.value;
            },
            use: function(key, defaultValue, now) {
              var savedValue;
              if (defaultValue == null) {
                defaultValue = null;
              }
              if (now == null) {
                now = (new Date()).getTime();
              }
              key = _genKey(key);
              savedValue = _getSavedValue(key, now);
              if (!savedValue) {
                return defaultValue;
              }
              savedValue.config[_confKey.LAST_USAGE_DATETIME] = now;
              webStorage.setItem(key, angular.toJson(savedValue));
              return savedValue.value;
            },
            set: function(key, value, expiredTime, now) {
              var savedValue, _base, _name;
              if (now == null) {
                now = (new Date()).getTime();
              }
              key = _genKey(key);
              savedValue = angular.fromJson(webStorage.getItem(key));
              if (!(savedValue && savedValue.config && savedValue.value)) {
                savedValue = {
                  config: {}
                };
              }
              savedValue.value = value;
              if (expiredTime) {
                savedValue.config[_confKey.EXPIRED_TIME] = expiredTime;
              }
              if ((_base = savedValue.config)[_name = _confKey.CREATE_DATETIME] == null) {
                _base[_name] = now;
              }
              savedValue.config[_confKey.LAST_USAGE_DATETIME] = now;
              webStorage.setItem(key, angular.toJson(savedValue));
              keys.set(key);
              return this;
            },
            del: function(key) {
              var value;
              value = this.get(key);
              key = _genKey(key);
              webStorage.removeItem(key);
              keys.del(key);
              return value;
            },
            delAll: function() {
              return keys.delAll();
            }
          };
          return storage;
        };
        storageFactory = function(webStorage) {
          var Keys, _keysList, _storages;
          _refreshRevisions(webStorage);
          _storages = {};
          _keysList = angular.fromJson(webStorage.getItem(_keysListKey) || "{}");
          Keys = function(prefix) {
            var self, _keys;
            _keys = _keysList[prefix] != null ? _keysList[prefix] : _keysList[prefix] = {};
            self = {
              get: function(key) {
                return _keys[key] || false;
              },
              set: function(key) {
                _keys[key] = true;
                webStorage.setItem(_keysListKey, angular.toJson(_keysList));
                return self;
              },
              del: function(key) {
                delete _keys[key];
                return webStorage.setItem(_keysListKey, angular.toJson(_keysList));
              },
              delAll: function() {
                var k;
                for (k in _keys) {
                  webStorage.removeItem(k);
                  delete _keys[k];
                }
                return webStorage.setItem(_keysListKey, angular.toJson(_keysList));
              }
            };
            return self;
          };
          return function(prefix) {
            return _storages[prefix] != null ? _storages[prefix] : _storages[prefix] = AmoStorage(webStorage, prefix, Keys(prefix));
          };
        };
        return {
          getLocalStorage: storageFactory(localStorage),
          getSessionStorage: storageFactory(sessionStorage)
        };
      }
    };
    return provider;
  });

}).call(this);
