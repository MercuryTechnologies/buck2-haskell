{-# LANGUAGE ForeignFunctionInterface #-}

module A where

foreign import ccall safe "print_from_clib"
  c_print_from_clib :: IO ()
