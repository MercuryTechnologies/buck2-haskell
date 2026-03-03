module Resources.ResourcesSpec where

import Data.Aeson (throwDecode)
import Data.ByteString qualified as BS
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Resources.LibExportingResource
import System.Environment (getExecutablePath)
import System.FilePath (takeDirectory, (</>))
import Test.Hspec

data ResourceDB = ResourceDB
  { baseDir :: FilePath
  , resources :: Map String String
  }
  deriving stock (Show)

readResourceDB :: IO ResourceDB
readResourceDB = do
  exePath <- getExecutablePath
  let baseDir = takeDirectory exePath
      dbPath = exePath ++ ".resources.json"
  contents <- BS.readFile dbPath
  resources <- throwDecode @(Map String String) (BS.fromStrict contents)

  pure ResourceDB {baseDir, resources}

readResource :: String -> ResourceDB -> IO BS.ByteString
readResource name db = do
  filename <-
    maybe (fail $ "missing resource " <> name) pure $
      Map.lookup name db.resources
  BS.readFile (db.baseDir </> filename)

withResourceDB :: SpecWith ResourceDB -> Spec
withResourceDB = beforeAll readResourceDB

main :: IO ()
main = hspec do
  withResourceDB $ describe "resources" do
    it "test_resource.txt is readable" \db -> do
      content <- readResource resourceName db
      content `shouldBe` "Hello from a resource file!\n"

    it "subdir.txt is readable" \db -> do
      content <- readResource subdirResource db
      content `shouldBe` "resource!!\n"

    it "resource2.txt is readable" \db -> do
      content <- readResource "tests/Resources/resource2.txt" db
      content `shouldBe` "resource!\n"
