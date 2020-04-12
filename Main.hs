module Main where

import qualified Data.ByteString.Lazy as ByS (ByteString, readFile, writeFile, length)
import qualified Data.BitString as BiS (BitString, toList, fromList, bitStringLazy, append, realizeBitStringLazy, take, drop)
import Data.Word (Word16, Word8)
import Data.Bits ((.&.))
import System.Environment (getArgs)
import Data.List.Split (chunksOf, splitOneOf, splitOn)
import Data.List (intercalate)
import System.IO (hFileSize, withFile, IOMode (ReadMode))

main :: IO ()
main = do
  args <- getArgs
  case length args of
    2 -> case safeHead args of
           Just "-s" -> splitFile $ args!!1
           _         -> printInstructions
    3 -> case safeHead args of
           Just "-f" -> fuseFile (args!!1) (args!!2)
           _         -> printInstructions
    _ -> printInstructions

safeHead :: [a] -> Maybe a
safeHead (h:_) = Just h
safeHead _     = Nothing

printInstructions :: IO ()
printInstructions = putStrLn $ "\tBinary Fusion:\nSplit file:\tbf -s [input filepath]\nFuse file:\tbf -f [fragment1] [fragment2]"

{-|
Takes the bytes of a file, and splits them bit-by-bit. If the input file started with bits
ABCDEFGH, the first output file would start with bits ACEG, and the second would start with
bits BDFH. If the number of bytes in the input file is odd, there won't be enough bits to form
the full bytes at the end, so we have to buffer it out a bit.

Each split file will have a header consisting of a single byte. The first bit tells BF whether
the file is the left (1) or right (0) file for meshing them back together. The second bit tells BF
whether there was an even number of bytes (0) or an odd number of bytes (1) in the original file.
The third and forth bits are unused for now. If there was an even number of bytes in the input,
then bits 5 through 8 will be buffered with 0's. If there was an odd number of bytes in the input,
bits 5 through 8 will have the first nibble of data as an offset so everything fits neatly into
normal bytes.
-}
splitFile :: String -> IO ()
splitFile filePath = do
  fileSize <- withFile filePath ReadMode hFileSize
  bytes    <- ByS.readFile filePath
  
  let (left, right) = unmeshBits $ BiS.bitStringLazy bytes
  let fileName      = head . tail . reverse $ splitOneOf "/." filePath
  let fileDir       = (intercalate "/" . reverse . tail . reverse $ splitOn "/" filePath) ++ "/"
  let header        = if rem fileSize 2 == 0 -- This initialization doesn't include the first left/right bit
                         then replicate 7 False
                         else [True, False, False]

  let leftBytes     = BiS.realizeBitStringLazy $ BiS.append (BiS.fromList (True  : header)) left
  let rightBytes    = BiS.realizeBitStringLazy $ BiS.append (BiS.fromList (False : header)) right

  ByS.writeFile (fileDir ++ fileName ++ "1") leftBytes
  ByS.writeFile (fileDir ++ fileName ++ "2") rightBytes

fuseFile :: String -> String -> IO ()
fuseFile filePath1 filePath2 = do

  byteString1 <- ByS.readFile filePath1
  byteString2 <- ByS.readFile filePath2

  let bitString1 = BiS.bitStringLazy byteString1
  let bitString2 = BiS.bitStringLazy byteString2

  let left  = if head . BiS.toList $ BiS.take 1 bitString1
                then bitString1
                else bitString2

  let right = if head . BiS.toList $ BiS.take 1 bitString1
                then bitString2
                else bitString1

  let fileDir    = (intercalate "/" . reverse . tail . reverse $ splitOn "/" filePath1) ++ "/"

  let headerSize = if (BiS.toList left)!!1
                     then 4
                     else 8

  let output      = meshBits (BiS.drop headerSize left) (BiS.drop headerSize right)
  let outputBytes = BiS.realizeBitStringLazy output

  ByS.writeFile (fileDir ++ "fusedFile") outputBytes

unmeshBits :: BiS.BitString -> (BiS.BitString, BiS.BitString)
unmeshBits input = let twoBits     = chunksOf 2 (BiS.toList input)
                       leftStream  = map head twoBits
                       rightStream = map last twoBits in
                     (BiS.fromList leftStream, BiS.fromList rightStream)

meshBits :: BiS.BitString -> BiS.BitString -> BiS.BitString
meshBits left right = let l = BiS.toList left
                          r = BiS.toList right in
                        BiS.fromList . concat $ zipWith (\a b -> [a, b]) l r
