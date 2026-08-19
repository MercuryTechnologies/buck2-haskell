-- | Tests that we can use haddock when the exports depend on toolchain
-- libraries
module Lib(greeting, dependOnExample, Example) where

import Test.Hspec (Example)

greeting :: String
greeting = "Hello from Lib"

-- | We refer to 'Example' to test haddock.
dependOnExample :: Example () => ()
dependOnExample = ()
