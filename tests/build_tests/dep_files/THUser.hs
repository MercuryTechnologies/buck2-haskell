{-# LANGUAGE TemplateHaskell #-}
module THUser (msg) where

import Dep (greeting)

msg :: String
msg = $(greeting)
