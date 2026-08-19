-- | Tests that we can use haddock when the exports depend on toolchain
-- libraries
module Lib(dependOnExample, Example) where

import Test.Hspec (Example)

-- | We refer to 'Example' to test haddock.
dependOnExample :: Example () => ()
dependOnExample = ()
