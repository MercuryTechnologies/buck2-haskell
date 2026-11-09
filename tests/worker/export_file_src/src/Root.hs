module Root (rooted) where

import Exported.Leaf (leaf)

rooted :: String
rooted = "Rooted, after: " ++ leaf
