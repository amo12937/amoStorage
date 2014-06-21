"use strict"

describe "amoStorage module", ->
  beforeEach module "amo.webStorage"

  describe "amoStorageProvider", ->
    describe "setAppPrefix method", ->
      it "should return provider", ->
        module ["amoStorageProvider", (provider) ->
          expect(provider.setAppPrefix("")).toBe provider
        ]
    describe "getAppPrefix method", ->
      it "should return 'amoStorage' as default", ->
        module ["amoStorageProvider", (provider) ->
          expect(provider.getAppPrefix()).toBe "amoStorage"
        ]
      it "should return an appPrefix that was set by using setAppPrefix method", ->
        module ["amoStorageProvider", (provider) ->
          expect(provider.setAppPrefix("hoge").getAppPrefix()).toBe "hoge"
        ]

    describe "setSeparator method", ->
      it "should return provider", ->
        module ["amoStorage", (provider) ->
          expect(provider.setSeparator("")).toBe provider
        ]
    describe "getSeparator method", ->
      it "should return '.' as default", ->
        module ["amoStorageProvider", (provider) ->
          expect(provider.getSeparator()).toBe "."
        ]
      it "should return a separator that was set by using setSeparator method", ->
        module ["amoStorageProvider", (provider) ->
          expect(provider.setSeparator("/").getSeparator()).toBe "/"
        ]

  describe "amoStorage", ->
    appPrefix = "appPrefixForTest"
    separator = "/"
    prefix = "somePrefix"
    beforeEach ->
      module ["amoStorageProvider", (provider) ->
        provider
        .setAppPrefix appPrefix
        .setSeparator separator
        return null
      ]

    describe "getAppPrefix method", ->
      it "should return an appPrefix that was set by amoStorageProvider", ->
        inject ["amoStorage", (amoStorage) ->
          expect(amoStorage.getAppPrefix()).toBe appPrefix
        ]

    describe "setSeparator", ->
      it "should return a separator that was set by amoStorageProvider", ->
        inject ["amoStorage", (amoStorage) ->
          expect(amoStorage.getSeparator()).toBe separator
        ]

    describe "getLocalStorage method", ->
      it "should be idempotent", ->
        inject ["amoStorage", (amoStorage) ->
          s1 = amoStorage.getLocalStorage prefix
          s2 = amoStorage.getLocalStorage prefix
          expect(s2).toBe s1
        ]
