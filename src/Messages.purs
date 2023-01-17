module Waterbot.Messages where

import Prelude

import Data.Array (index, length)
import Data.Maybe
import Data.String (replace)
import Effect.Random
import Data.String.Pattern (Pattern(..), Replacement(..))
import Effect
import Effect.Exception (throw)
import Data.DateTime.Instant
import Effect.Now
import Data.Number.Format (toString)
import Data.Time.Duration

import Data.Int (floor, toNumber)

type Messages = Array String

type Handle = String

getMessage :: Handle -> Messages -> Effect String
getMessage handle messages = do
    arrLen <- case length messages of
                v
                    | v == 0 -> throw "Messages cannot be of length 0"
                    | otherwise -> pure v
    randomScale <- random
    ix <- pure $ floor $ (toNumber arrLen) * randomScale
    message <- pure $ case index messages ix of
        Just msg -> msg
        Nothing -> "<username> drink water, also something is wrong in my code please help me"
    replaced <- pure $ replace (Pattern "<username>") (Replacement handle) message
    instant <- now
    (Milliseconds m) <- pure $ unInstant instant
    pure $ replaced <> " (" <> (toString m) <> ")"

