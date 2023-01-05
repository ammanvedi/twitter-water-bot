{-
Welcome to a Spago project!
You can edit this file as you like.

Need help? See the following resources:
- Spago documentation: https://github.com/purescript/spago
- Dhall language tour: https://docs.dhall-lang.org/tutorials/Language-Tour.html

When creating a new Spago project, you can use
`spago init --no-comments` or `spago init -C`
to generate this file without the comments in this block.
-}
{ name = "purescript-lambda"
, dependencies =
  [ "aff"
  , "aff-promise"
  , "argonaut-codecs"
  , "argonaut-core"
  , "arrays"
  , "console"
  , "crypto"
  , "debug"
  , "effect"
  , "either"
  , "exceptions"
  , "fetch"
  , "fetch-argonaut"
  , "foldable-traversable"
  , "foreign-object"
  , "http-methods"
  , "integers"
  , "js-uri"
  , "maybe"
  , "node-buffer"
  , "node-process"
  , "numbers"
  , "ordered-collections"
  , "prelude"
  , "spec"
  , "spec-discovery"
  , "strings"
  , "transformers"
  , "tuples"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
