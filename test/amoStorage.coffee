"use strict"

describe "amoStorage module", ->
  beforeEach ->
    localStorage.clear()
    sessionStorage.clear()
    module "amo.webStorage"

  describe "amoStorageManagerProvider", ->
    it "should have 'appName' property and the default is 'amoStorage'", ->
      module ["amoStorageManagerProvider", (provider) ->
        expect(provider.appName).toBe "amoStorage"
      ]

    it "should have 'revision' property and the default is '1.0.0'", ->
      module ["amoStorageManagerProvider", (provider) ->
        expect(provider.revision).toBe "1.0.0"
      ]

    it "should have 'separator' property and the default is '/'", ->
      module ["amoStorageManagerProvider", (provider) ->
        expect(provider.separator).toBe "/"
      ]

    it "should have 'keyGeneratorFactory' method that should create keyGenerator method", ->
      module ["amoStorageManagerProvider", (provider) ->
        keyGenerator = provider.keyGeneratorFactory("appName", "1.0.0", "/", "prefix")
        expect(keyGenerator "key").toBe "appName/1.0.0/prefix/key"
      ]

    it "should have 'ruleForDeletingRevisions' method that should always return true as a default", ->
      module ["amoStorageManagerProvider", (provider) ->
        expect(provider.ruleForDeletingRevisions("1.0.1")).toBe true
      ]

  describe "amoStorageManager", ->
    prefix = "prefix"
    anotherPrefix = "anotherPrefix"
    describe "getLocalStorage method", ->
      it "should have return the same object on the same input", ->
        inject ["amoStorageManager", (manager) ->
          s1 = manager.getLocalStorage prefix
          s2 = manager.getLocalStorage prefix
          expect(s2).toBe s1
        ]

      it "should have return the different object on the different input", ->
        inject ["amoStorageManager", (manager) ->
          s1 = manager.getLocalStorage prefix
          s2 = manager.getLocalStorage anotherPrefix
          expect(s2).not.toBe s1
        ]

    describe "getSessionStorage", ->
      it "should have return the same object on the same input", ->
        inject ["amoStorageManager", (manager) ->
          s1 = manager.getSessionStorage prefix
          s2 = manager.getSessionStorage prefix
          expect(s2).toBe s1
        ]

      it "should have return the different object on the different input", ->
        inject ["amoStorageManager", (manager) ->
          s1 = manager.getSessionStorage prefix
          s2 = manager.getSessionStorage anotherPrefix
          expect(s2).not.toBe s1
        ]

    it "should have return the different object between getLocalStorage and getSessionStorage", ->
      inject ["amoStorageManager", (manager) ->
        l = manager.getLocalStorage prefix
        s = manager.getSessionStorage anotherPrefix
        expect(s).not.toBe l
      ]

  testForWebStorage = (webStorage, webStorageName, getterName) ->
    describe webStorageName, ->
      appName = "app"
      revision = "1"
      separator = "."
      keyGeneratorFactory = (a, r, s, p) ->
        _p = "#{a}[#{r}]_#{p}#{s}"
        return (k) -> "#{_p}#{k}"

      keysKey = "app/1/keys$"
      revisionsKey = "app/revisions$"

      prefix = "prefix"
      storage = null

      key = "key"
      value = "value"

      expectedKey = "app[1]_prefix.key#"

      another =
        key: "anotherKey"
        value: "anotherValue"
        expectedKey: "app[1]_prefix.anotherKey#"

      beforeEach ->
        module ["amoStorageManagerProvider", (provider) ->
          provider.appName = appName
          provider.revision = revision
          provider.separator = separator
          provider.keyGeneratorFactory = keyGeneratorFactory
          return null
        ]
        inject ["amoStorageManager", (manager) ->
          storage = manager[getterName] prefix
        ]

      it "should set '#{revisionsKey}' key on #{webStorageName}", ->
        expect(webStorage.getItem(revisionsKey)).not.toBe null

      it "should set array as '#{revisionsKey}' and it has 1 value on #{webStorageName}", ->
        item = angular.fromJson(webStorage.getItem(revisionsKey))
        expect(item).toEqual [revision]

      it "should not set '#{keysKey}' key on #{webStorageName}", ->
        expect(webStorage.getItem(keysKey)).toBe null

      describe "'confKey' property", ->
        it "should have 'EXPIRED_TIME' key", ->
          expect(storage.confKey.EXPIRED_TIME).toBeDefined()

        it "should have 'CREATE_TIME' key", ->
          expect(storage.confKey.CREATE_DATETIME).toBeDefined()

        it "should have 'LAST_USAGE_TIME' key", ->
          expect(storage.confKey.LAST_USAGE_DATETIME).toBeDefined()

      describe "set method", ->
        it "should return storage-self", ->
          expect(storage.set key, value).toBe storage

        it "should set '#{expectedKey}' key on #{webStorageName}", ->
          storage.set key, value
          expect(webStorage.getItem(expectedKey)).not.toBe null

        it "should set an object that has 'value' key on #{webStorageName}", ->
          storage.set key, value
          item = angular.fromJson webStorage.getItem expectedKey
          expect(item.value).toBe value

        it "should set an object that has 'config' key on #{webStorageName}", ->
          storage.set key, value
          item = angular.fromJson webStorage.getItem expectedKey
          expect(item.config).toBeDefined()

        it "should set an object when null was set", ->
          storage.set key, value
          webStorage.setItem expectedKey, null
          storage.set key, value
          item = angular.fromJson webStorage.getItem expectedKey
          expect(item.config).toBeDefined()

        it "should update the value when set twice", ->
          storage.set key, value
          actual = storage.get key
          expect(actual).toBe value
          storage.set key, another.value
          anotherActual = storage.get key
          expect(anotherActual).toBe another.value

        describe "the config on #{webStorageName}", ->
          it "should have {confKey.CREATE_DATETIME} key and its value is the time of now", ->
            now = (new Date()).getTime()
            spyOn(Date.prototype, "getTime").and.returnValue now
            storage.set key, value
            item = angular.fromJson webStorage.getItem expectedKey
            expect(item.config[storage.confKey.CREATE_DATETIME]).toBe now

          it "should have {confKey.LAST_USAGE_DATETIME} key and its value is the time of now", ->
            now = (new Date()).getTime()
            spyOn(Date.prototype, "getTime").and.returnValue now
            storage.set key, value
            item = angular.fromJson webStorage.getItem expectedKey
            expect(item.config[storage.confKey.LAST_USAGE_DATETIME]).toBe now

        it "should set '#{keysKey}' key on #{webStorageName}", (done) ->
          inject ["$rootScope", ($rootScope) ->
            storage.set key, value
            $rootScope.$apply()
            setTimeout((->
              expect(webStorage.getItem(keysKey)).not.toBe null
              done()
            ), 110)
          ]

        it "should set the object as '#{keysKey}' on #{webStorageName}", (done) ->
          inject ["$rootScope", ($rootScope) ->
            storage.set key, value
            $rootScope.$apply()
            setTimeout((->
              item = angular.fromJson(webStorage.getItem(keysKey))
              expect(item[prefix][expectedKey]).toBe true
              done()
            ), 110)
          ]

        it "should update {confKey.LAST_USAGE_DATETIME} when setting value again", ->
          storage.set key, value
          now = (new Date()).getTime()
          spyOn(Date.prototype, "getTime").and.returnValue now + 10000
          storage.set key, another.value
          item = angular.fromJson webStorage.getItem expectedKey
          expect(item.config[storage.confKey.LAST_USAGE_DATETIME]).toBe now + 10000

        it "should not update {confKey.CREATE_DATETIME} when setting value again", ->
          storage.set key, value
          now = (new Date()).getTime()
          spyOn(Date.prototype, "getTime").and.returnValue now + 10000
          storage.set key, another.value
          item = angular.fromJson webStorage.getItem expectedKey
          expect(item.config[storage.confKey.CREATE_DATETIME]).not.toBe now + 10000

        it "should set expired time", ->
          storage.set key, value, 10
          item = angular.fromJson webStorage.getItem expectedKey
          expect(item.config[storage.confKey.EXPIRED_TIME]).toBe 10

      describe "get method", ->
        it "should return the default value on unset key", ->
          expect(storage.get key, "hoge").toBe "hoge"

        it "should return the value set by 'set' method", ->
          storage.set key, value
          expect(storage.get key, "hoge").toBe value

        it "should return the default value if storage was broken", ->
          storage.set key, "hoge"
          webStorage.setItem expectedKey, null
          expect(storage.get key, "hoge").toBe "hoge"

        it "should return the default value expired time after", ->
          storage.set key, value, 10
          now = (new Date()).getTime()
          spyOn(Date.prototype, "getTime").and.returnValue now + 11000
          expect(storage.get key, "hoge").toBe "hoge"

        it "should return the value set by 'set method before expired time", ->
          storage.set key, value, 10
          now = (new Date()).getTime()
          spyOn(Date.prototype, "getTime").and.returnValue now + 9000
          expect(storage.get key, "hoge").toBe value

        it "should not update {confKey.LAST_USAGE_DATETIME}", ->
          storage.set key, value
          now = (new Date()).getTime()
          spyOn(Date.prototype, "getTime").and.returnValue now + 10000
          storage.get key
          item = angular.fromJson webStorage.getItem expectedKey
          expect(item.config[storage.confKey.LAST_USAGE_DATETIME]).not.toBe now + 10000

      describe "use method", ->
        it "should return the default value on unset key", ->
          expect(storage.use key, "hoge").toBe "hoge"

        it "should return the value set by 'set' method", ->
          storage.set key, value
          expect(storage.use key, "hoge").toBe value

        it "should return the default value expired time after", ->
          storage.set key, value, 10
          now = (new Date()).getTime()
          spyOn(Date.prototype, "getTime").and.returnValue now + 11000
          expect(storage.use key, "hoge").toBe "hoge"

        it "should return the value set by 'set' method before expired time", ->
          storage.set key, value, 10
          now = (new Date()).getTime()
          spyOn(Date.prototype, "getTime").and.returnValue now + 9000
          expect(storage.use key, "hoge").toBe value

        it "should update {confKey.LAST_USAGE_DATETIME}", ->
          storage.set key, value
          now = (new Date()).getTime()
          spyOn(Date.prototype, "getTime").and.returnValue now + 10000
          storage.use key
          item = angular.fromJson webStorage.getItem expectedKey
          expect(item.config[storage.confKey.LAST_USAGE_DATETIME]).toBe now + 10000

      describe "del method", ->
        it "should return the old value set by 'set' method", ->
          storage.set key, value
          expect(storage.del key).toBe value

        it "should remove '#{expectedKey}' key on #{webStorageName}", ->
          storage.set key, value
          storage.del key
          expect(webStorage.getItem(expectedKey)).toBe null

        it "should remove storage['#{keysKey}']['#{prefix}']['#{expectedKey}']", (done) ->
          inject ["$rootScope", ($rootScope) ->
            storage.set key, value
            $rootScope.$apply()
            setTimeout((->
              storage.del key
              $rootScope.$apply()
              setTimeout((->
                item = angular.fromJson webStorage.getItem keysKey
                expect(item[prefix][expectedKey]).not.toBeDefined()
                done()
              ), 110)
            ), 110)
          ]
      describe "delAll method", ->
        it "should remove all of keys whose prefix is '#{prefix}' on #{webStorageName}", ->
          storage.set key, value
          storage.set another.key, another.value
          storage.delAll()
          expect(webStorage.getItem(expectedKey)).toBe null
          expect(webStorage.getItem(another.expectedKey)).toBe null

        it "should remove '#{prefix}' key on '#{keysKey}' key", (done) ->
          inject ["$rootScope", ($rootScope) ->
            storage.set key, value
            storage.set another.key, another.value
            $rootScope.$apply()
            setTimeout((->
              storage.delAll()
              $rootScope.$apply()
              setTimeout((->
                item = angular.fromJson webStorage.getItem keysKey
                expect(item[prefix]).toEqual({})
                done()
              ), 110)
            ), 110)
          ]

    describe "updating revision (#{webStorageName})", ->
      old =
        revision: "1"
        keysKey: "amoStorage/1/keys$"
        keys:
          prefix:
            "amoStorage/1/prefix/key#": "hoge"
            "amoStorage/1/prefix/key2#": "fuga"
          prefix2:
            "amoStorage/1/prefix2/key3#": "fizz"

      prev =
        revision: "2"
        keysKey: "amoStorage/2/keys$"
        keys:
          prefix:
            "amoStorage[2]_prefix.key#": "foo"
            "amoStorage[2]_prefix.key2#": "bar"
          prefix2:
            "amoStorage[2]_prefix2.key3#": "buz"

      current =
        revision: "3"

      revisions = ["1", "2"]
      revisionsKey = "amoStorage/revisions$"

      beforeEach ->
        f = (data) ->
          keys = {}
          for p, v of data.keys
            keys[p] = {}
            for k, v2 of v
              keys[p][k] = true
              webStorage.setItem k, v2
          webStorage.setItem data.keysKey, angular.toJson keys
        f old
        f prev
        webStorage.setItem revisionsKey, angular.toJson revisions

      it "should remove all keys of prev revisions", ->
        module ["amoStorageManagerProvider", (provider) ->
          provider.revision = current.revision
          return null
        ]
        inject ["amoStorageManager", (manager) ->
          expect(angular.fromJson webStorage.getItem revisionsKey).toEqual [current.revision]
          expect(webStorage.getItem old.keysKey).toBe null
          for p, v of old.keys
            for k of v
              expect(webStorage.getItem k).toBe null
          expect(webStorage.getItem prev.keysKey).toBe null
          for p, v of prev.keys
            for k of v
              expect(webStorage.getItem k).toBe null
        ]

      it "should not remove prev revision when setting ruleForDeletingRevisions", ->
        module ["amoStorageManagerProvider", (provider) ->
          provider.revision = current.revision
          provider.ruleForDeletingRevisions = (revision) -> revision isnt prev.revision
          return null
        ]
        inject ["amoStorageManager", (manager) ->
          expect(angular.fromJson webStorage.getItem revisionsKey).toEqual [current.revision, prev.revision]
          expect(webStorage.getItem old.keysKey).toBe null
          for p, v of old.keys
            for k of v
              expect(webStorage.getItem k).toBe null
          expect(webStorage.getItem prev.keysKey).not.toBe null
          for p, v of prev.keys
            for k of v
              expect(webStorage.getItem k).not.toBe null
        ]

  testForWebStorage(localStorage, "localStorage", "getLocalStorage")
  testForWebStorage(sessionStorage, "sessionStorage", "getSessionStorage")
