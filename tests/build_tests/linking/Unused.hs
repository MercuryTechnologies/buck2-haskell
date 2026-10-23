-- Not imported by app.hs. Its object references a symbol that doesn't exist,
-- so linking `:app` fails if objects outside the main module's closure are
-- linked.
module Unused where

foreign import ccall "buck2_haskell_test_symbol_that_does_not_exist"
  missingSymbol :: IO ()

unused :: IO ()
unused = missingSymbol
