module Main where

import B
import System.Exit (exitSuccess)

main :: IO ()
main = testTransitiveFFICall >> exitSuccess
