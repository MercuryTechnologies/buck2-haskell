module Orphan.Base (constrained) where

import Orphan.Class (C (..))

constrained :: C a => a -> Int
constrained = c
