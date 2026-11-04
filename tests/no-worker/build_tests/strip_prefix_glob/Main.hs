module Main where

import Stripped.Lib (greeting)
import Stripped.Inner (farewell)

main :: IO ()
main = do
  putStrLn greeting
  putStrLn farewell
