{-# LANGUAGE ForeignFunctionInterface #-}

module A where

import Foreign.C.String (CString, peekCString)

foreign import ccall safe "zlibVersion"
  zlibVersion :: IO CString

printZlibVersion :: IO ()
printZlibVersion = do
  c_str <- zlibVersion
  str <- peekCString c_str
  putStrLn ("zlib version = " ++ str)

