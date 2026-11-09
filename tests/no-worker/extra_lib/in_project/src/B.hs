module B where

import A (c_print_from_clib)

testTransitiveFFICall :: IO ()
testTransitiveFFICall = do
  c_print_from_clib
  putStrLn "FFI call from dependency succeeded"
