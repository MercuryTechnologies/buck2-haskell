module C where

foreign import ccall safe "print_from_clib_2"
  c_print_from_clib_2 :: IO ()
