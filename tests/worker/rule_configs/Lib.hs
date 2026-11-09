-- | Tests that we can use haddock when the exports depend on toolchain
-- libraries
module Lib(greeting, dependOnExample, Example) where

import Test.Hspec (Example)
import LibB (greetingB)

greeting :: String
greeting = greetingB

-- | We refer to 'Example' to test haddock.
dependOnExample :: Example () => ()
dependOnExample = ()
