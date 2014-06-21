"use strict"

describe "amoStorage の仕様", ->
  beforeEach module "amo.webStorage"

  describe "amoStorageProvider は", ->
    describe "appPrefix を登録できる：", ->
      it "appPrefix のデフォルト値は amoStorage である", ->
        module ["amoStorageProvider", (provider) ->
          expect(provider.getAppPrefix()).toBe "amoStorage"
        ]
      it "setAppPrefix は provider 自身を返す", ->
        module ["amoStorageProvider", (provider) ->
          expect(provider.setAppPrefix("")).toBe provider
        ]
      it "setAppPrefix で設定した appPrefix は getAppPrefix で取得できる", ->
        module ["amoStorageProvider", (provider) ->
          expect(provider.setAppPrefix("hoge").getAppPrefix()).toBe "hoge"
        ]

      it "provider.setAppPrefix で設定した appPrefix は amoStorage.getAppPrefix で取得できる", ->
        module ["amoStorageProvider", (provider) ->
          provider.setAppPrefix("fuga")
          return null
        ]
        inject ["amoStorage", (amoStorage) ->
          expect(amoStorage.getAppPrefix()).toBe "fuga"
        ]

    describe "separator を登録できる：", ->
      it "separator のデフォルト値は . である", ->
        module ["amoStorageProvider", (provider) ->
          expect(provider.getSeparator()).toBe "."
        ]
      it "setSeparator は provider 自身を返す", ->
        module ["amoStorage", (provider) ->
          expect(provider.setSeparator("")).toBe provider
        ]
      it "setSeparator で設定した separator は getSeparator で取得できる", ->
        module ["amoStorageProvider", (provider) ->
          expect(provider.setSeparator("/").getSeparator()).toBe "/"
        ]

      it "provider.setSeparator で設定した separator は amoStorage.getSeparator で取得できる", ->
        module ["amoStorageProvider", (provider) ->
          provider.setSeparator(":")
          return null
        ]
        inject ["amoStorage", (amoStorage) ->
          expect(amoStorage.getSeparator()).toBe ":"
        ]

  describe "amoStorage は", ->
    appPrefix = "appPrefixForTest"
    separator = "/"
    prefix = "hogePrefix"

    beforeEach ->
      module ["amoStorageProvider", (provider) ->
        provider.setAppPrefix(appPrefix)
        .setSeparator(separator)
        return null
      ]
    describe "localStorage のラッパーを提供する：", ->
      it "同じ prefix は同じ storage を返す", ->
        inject ["amoStorage", (amoStorage) ->
          s1 = amoStorage.getLocalStorage prefix
          s2 = amoStorage.getLocalStorage prefix
          expect(s2).toBe s1
        ]
