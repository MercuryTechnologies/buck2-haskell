module Main where

import Dict.Lib (greeting)
import Dict.Inner (farewell)

main :: IO ()
main = do
  putStrLn greeting
  putStrLn farewell
