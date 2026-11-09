module Main where

import Acme.Foo.Bar.Lib (greeting)
import Acme.Foo.Bar.Other (farewell)

main :: IO ()
main = do
  putStrLn greeting
  putStrLn farewell
