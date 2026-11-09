-- | Tests that we can use haddock when the exports depend on other libraries
module Lib2(dependOnExample2) where

import Lib

-- | Like 'dependOnExample'
dependOnExample2 :: Example () => ()
dependOnExample2 = dependOnExample
