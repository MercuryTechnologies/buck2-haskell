{-# LANGUAGE TypeFamilies #-}

module Finst.Inst (T (..)) where

import Finst.Fam (F)

data T = MkT

type instance F T = Int
