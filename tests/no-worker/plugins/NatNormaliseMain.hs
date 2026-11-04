
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NoStarIsType #-}
{-# LANGUAGE TypeOperators #-}

import Data.Proxy
import GHC.TypeNats

test :: KnownNat n => Proxy (n + n) -> Proxy (2 * n)
test = id

main :: IO ()
main = pure ()
