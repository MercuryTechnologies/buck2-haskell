-- | Tests that we can use haddock when there is more than one module in the
-- library
module LibB(greetingB, dependOnExampleB) where

import Test.Hspec (Example)

greetingB :: String
greetingB = "Hello from Lib"

dependOnExampleB :: Example () => ()
dependOnExampleB = ()
