module Acme.Foo.Bar.Other (farewell) where

import Acme.Foo.Bar.Lib (greeting)

farewell :: String
farewell = "Goodbye, after: " ++ greeting
