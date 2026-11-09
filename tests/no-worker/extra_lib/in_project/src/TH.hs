module TH where

import A (c_print_from_clib)
import Control.Monad.IO.Class (liftIO)
import Language.Haskell.TH (Q, Dec)

th_test :: Q [Dec]
th_test = do
  liftIO c_print_from_clib
  pure []

