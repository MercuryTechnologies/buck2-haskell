{-# LANGUAGE TemplateHaskell #-}

module C where

import TH (th_test)

$(th_test)

