module D where

import C (c_print_from_clib_2)

testTransitiveFFICall :: IO ()
testTransitiveFFICall = do
  c_print_from_clib_2
  putStrLn "FFI call from dependency succeeded"
