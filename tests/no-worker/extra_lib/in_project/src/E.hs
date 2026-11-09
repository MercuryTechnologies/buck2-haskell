{-# LANGUAGE TemplateHaskell #-}

module E where

import TH (th_test)

$(th_test)
