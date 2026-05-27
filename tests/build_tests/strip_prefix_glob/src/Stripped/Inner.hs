module Stripped.Inner (farewell) where

import Stripped.Lib (greeting)

farewell :: String
farewell = "Goodbye, after: " ++ greeting
