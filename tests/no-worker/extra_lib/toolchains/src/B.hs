module B where

import A (printZlibVersion)

testTransitiveFFICall :: IO ()
testTransitiveFFICall = do
  printZlibVersion
  putStrLn "FFI call from dependency succeeded"
