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
      $get: [
        "$rootScope", function($rootScope) {
          var AmoStorage, storageFactory, _appName, _deleteKeys, _deleteRevision, _genKeysKey, _keyGeneratorFactory, _keysKey, _refreshRevisions, _revision, _revisionsKey, _ruleForDeletingRevisions, _separator, _suffix, _suffixForSys;
          _appName = provider.appName;
          _revision = provider.revision;
          _separator = provider.separator;
          _keyGeneratorFactory = provider.keyGeneratorFactory;
          _ruleForDeletingRevisions = provider.ruleForDeletingRevisions;
          _suffix = "#";
          _suffixForSys = "$";
          _genKeysKey = function(revision) {
            return "" + _appName + "/" + revision + "/keys" + _suffixForSys;
          };
          _keysKey = _genKeysKey(_revision);
          _revisionsKey = "" + _appName + "/revisions" + _suffixForSys;
          _deleteKeys = function(webStorage, keys) {
            var key, _results;
            _results = [];
            for (key in keys) {
              webStorage.removeItem(key);
              _results.push(delete keys[key]);
            }
            return _results;
          };
          _deleteRevision = function(webStorage, revision) {
            var keys, keysKey, p, v;
            keysKey = _genKeysKey(revision);
            keys = angular.fromJson(webStorage.getItem(keysKey));
            for (p in keys) {
              v = keys[p];
              _deleteKeys(webStorage, v);
            }
            return webStorage.removeItem(keysKey);
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
              if (!keys[key]) {
                return null;
              }
              savedValue = angular.fromJson(webStorage.getItem(key));
              if (now - savedValue.config[_confKey.LAST_USAGE_DATETIME] > savedValue.config[_confKey.EXPIRED_TIME] * 1000) {
                webStorage.removeItem(key);
                delete keys[key];
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
                savedValue = keys[key] ? angular.fromJson(webStorage.getItem(key)) : {
                  config: {},
                  value: value
                };
                if (expiredTime) {
                  savedValue.config[_confKey.EXPIRED_TIME] = expiredTime;
                }
                if ((_base = savedValue.config)[_name = _confKey.CREATE_DATETIME] == null) {
                  _base[_name] = now;
                }
                savedValue.config[_confKey.LAST_USAGE_DATETIME] = now;
                webStorage.setItem(key, angular.toJson(savedValue));
                keys[key] = true;
                return this;
              },
              del: function(key) {
                var value;
                value = this.get(key);
                key = _genKey(key);
                webStorage.removeItem(key);
                delete keys[key];
                return value;
              },
              delAll: function() {
                return _deleteKeys(webStorage, keys);
              }
            };
            return storage;
          };
          storageFactory = function(webStorage) {
            var k, p, v, _debounce, _keys, _prevKeys, _storages;
            _refreshRevisions(webStorage);
            _storages = {};
            _keys = angular.fromJson(webStorage.getItem(_keysKey) || "{}");
            _prevKeys = {};
            for (p in _keys) {
              v = _keys[p];
              _prevKeys[p] = {};
              for (k in v) {
                _prevKeys[p][k] = true;
              }
            }
            _debounce = null;
            $rootScope.$watch(function() {
              return _debounce || (_debounce = setTimeout((function() {
                var b, _oldKeys, _ref, _ref1;
                _debounce = null;
                _oldKeys = _prevKeys;
                _prevKeys = {};
                b = false;
                for (p in _keys) {
                  v = _keys[p];
                  _prevKeys[p] = {};
                  for (k in v) {
                    _prevKeys[p][k] = true;
                    b || (b = !((_ref = _oldKeys[p]) != null ? _ref[k] : void 0));
                    if ((_ref1 = _oldKeys[p]) != null) {
                      delete _ref1[k];
                    }
                  }
                  b || (b = !util.isEmptyObj(_oldKeys[p]));
                }
                if (b) {
                  return webStorage.setItem(_keysKey, angular.toJson(_prevKeys));
                }
              }), 100));
            });
            return function(prefix) {
              return _storages[prefix] != null ? _storages[prefix] : _storages[prefix] = AmoStorage(webStorage, prefix, _keys[prefix] != null ? _keys[prefix] : _keys[prefix] = {});
            };
          };
          return {
            getLocalStorage: storageFactory(localStorage),
            getSessionStorage: storageFactory(sessionStorage)
          };
        }
      ]
    };
    return provider;
  });

}).call(this);

//# sourceMappingURL=amoStorage.js.map
