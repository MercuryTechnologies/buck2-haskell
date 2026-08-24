module B where

import A (print_from_clib)

testTransitiveFFICall :: IO ()
testTransitiveFFICall = do
  print_from_clib
  putStrLn "FFI call from dependency succeeded"
