{-# LANGUAGE TemplateHaskell #-}

module TH where

import A (printZlibVersion)
import Control.Monad.IO.Class (liftIO)
import Language.Haskell.TH (Q, Dec)

th_test :: Q [Dec]
th_test = do
   liftIO printZlibVersion
   pure []
