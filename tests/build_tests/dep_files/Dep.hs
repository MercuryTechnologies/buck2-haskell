module Dep (answer, greeting) where

import Base (hello)
import Language.Haskell.TH.Syntax (Exp, Q, lift)

answer :: Int
answer = 42

greeting :: Q Exp
greeting = lift hello
