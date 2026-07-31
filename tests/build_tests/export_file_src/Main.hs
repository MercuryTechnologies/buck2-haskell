module Main where

import Exported.Leaf (leaf)
import Root (rooted)

main :: IO ()
main = do
  putStrLn leaf
  putStrLn rooted
