module TestResources where

import Control.Monad (unless)
import Data.Aeson (eitherDecodeStrict')
import Data.ByteString qualified as BS
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import System.Directory (doesFileExist)
import System.Environment (getExecutablePath)
import System.Exit (exitFailure, exitSuccess)
import System.FilePath (takeDirectory, (</>))

main :: IO ()
main = do
  exePath <- getExecutablePath
  let dir = takeDirectory exePath
      dbPath = exePath ++ ".resources.json"

  dbExists <- doesFileExist dbPath
  if not dbExists
    then do
      fail $ "FAIL: resources.json not found at: " ++ dbPath
    else do
      contents <- BS.readFile dbPath
      case eitherDecodeStrict' contents :: Either String (Map String String) of
        Left err -> do
          fail $ "FAIL: could not parse resources.json: " ++ err
        Right db
          | Map.null db -> do
              fail "FAIL: resources.json is empty"
          | otherwise -> do
              putStrLn $ "Found " ++ show (Map.size db) ++ " resource(s):"
              unless (Map.keysSet db `Set.isSubsetOf` Set.fromList ["tests/test_resource2.txt", "tests/test_resource.txt"]) $
                fail $ "Missing resources. Have: " ++ show db
              results <- mapM (checkResource dir) (Map.toList db)
              if and results
                then do
                  putStrLn "OK: all resources verified"
                else do
                  fail "FAIL: some resources not materialized"

checkResource :: FilePath -> (String, String) -> IO Bool
checkResource dir (name, relPath) = do
  let fullPath = dir </> relPath
  exists <- doesFileExist fullPath
  if exists
    then do
      putStrLn $ "  OK: " ++ name ++ " -> " ++ relPath
      return True
    else do
      putStrLn $ "  MISSING: " ++ name ++ " -> " ++ fullPath
      return False
