"use strict"

describe "amoStorage の仕様", ->
  beforeEach module "amo.webStorage"

  it "forTest", ->
    inject ["forTest", (forTest) ->
      expect(forTest).toBe "forTest"
    ]

