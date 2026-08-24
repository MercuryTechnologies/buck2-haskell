{-# LANGUAGE ForeignFunctionInterface #-}

module A where

foreign import ccall safe "print_from_clib"
  print_from_clib :: IO ()
