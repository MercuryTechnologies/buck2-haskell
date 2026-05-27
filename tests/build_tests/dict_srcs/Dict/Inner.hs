module Dict.Inner (farewell) where

import Dict.Lib (greeting)

farewell :: String
farewell = "Goodbye, after: " ++ greeting
