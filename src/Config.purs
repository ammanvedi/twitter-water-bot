module Waterbot.Config (getConfig, WaterbotConfig(..)) where

import Prelude
import Effect
import Data.Array
import Data.Maybe
import Data.Either
import Node.Process (lookupEnv)
import Node.FS.Sync (readTextFile)
import Node.Encoding (Encoding(..))
import Data.Argonaut.Parser (jsonParser)
import Data.Argonaut.Decode
import Data.Argonaut.Core (Json, toObject, toArray, toString)
import Effect.Exception (throwException, error)
import Foreign.Object (lookup, Object)
import Data.Traversable (sequence)

newtype JsonConfig = JsonConfig {
    targetHandles :: Array String,
    messages :: Array String
}

decodeObjectField :: forall a. String -> Object Json -> (Json -> Maybe a) -> Maybe a
decodeObjectField key obj parseFunc = do
    jsonValue <- lookup key obj
    parseFunc jsonValue

decodeArray :: forall a. Array Json -> (Json -> Maybe a) -> Maybe (Array a)
decodeArray arr parseFunc = do
    decodeAttempt <- pure $ parseFunc <$> arr
    sequence decodeAttempt

--decodeOrThrow :: forall a. String -> Object Json -> (Json -> Maybe a) -> Effect a
--decodeOrThrow key obj parseFunc =
--    case decodeObjectField key obj parseFunc of
--        Nothing -> throwException $ error $ "Field " <> key <> " could not be decoded from config"
--        Just v -> pure v
--
--decodeArrayOrThrow :: forall a. String -> Object Json -> (Json -> Maybe a) -> Effect a
--decodeArrayOrThrow key obj parseElFunc = do
--    jsonArray <- case decodeObjectField key obj toArray of
--        Nothing -> throwException $ error $ "Field " <> key <> " could not be decoded to an array"
--        Just v -> pure v
--    case decodeArray jsonArray parseElFunc of
--        Nothing _ -> throwException $ error $ "Field " <> key <> " could not be decoded to an array of the expected type"
--        Just a -> pure a



instance jsonConfigDecode :: DecodeJson JsonConfig where
    decodeJson json = do
        rootObject <- case toObject json of
                        Nothing -> Left $ TypeMismatch "Expected root to be an object"
                        Just o -> pure o
        targetHandlesRaw <- case decodeObjectField "targetHandles" rootObject toArray of
                                Nothing -> Left $ TypeMismatch "Could not find targetHandles property in config object"
                                Just o -> pure o
        targetHandles <- case decodeArray targetHandlesRaw toString of
                                 Nothing -> Left $ TypeMismatch "Could not decode targte handles array in config"
                                 Just o -> pure o
        messagesRaw <- case decodeObjectField "messages" rootObject toArray of
                                Nothing -> Left $ TypeMismatch "Could not find messages property in config object"
                                Just o -> pure o
        messages <- case decodeArray messagesRaw toString of
                        Nothing -> Left $ TypeMismatch "Could not decode messages array in config"
                        Just o -> pure o
        pure $ JsonConfig { targetHandles: targetHandles, messages: messages }

newtype WaterbotConfig = WaterbotConfig {
    twitterConsumerKey  :: String,
    twitterConsumerSecret :: String,
    twitterAccessToken :: String,
    twitterAccessTokenSecret :: String,
    targetHandles :: Array String,
    messages :: Array String
}

readJsonConfig :: Effect JsonConfig
readJsonConfig = do
    fileContent <- readTextFile UTF8 "./bot.config.json"
    jsonParseResult <- pure $ jsonParser fileContent
    json <- case jsonParseResult of
                Left _ -> throwException $ error "Could not parse bot config string"
                Right jsn -> pure jsn
    case decodeJson json of
        Left e -> throwException $ error "Config format invalid"
        Right config -> pure config

getEnvarOrThrow :: String -> Effect String
getEnvarOrThrow e = do
    envLookupResult <- lookupEnv e
    case envLookupResult of
        Nothing -> throwException $ error $ "could not find envar " <> e
        Just envar -> pure envar

getConfig :: Effect WaterbotConfig
getConfig = do
        twitterConsumerKey  <-  getEnvarOrThrow "TF_VAR_twitter_consumer_key"
        twitterConsumerSecret <- getEnvarOrThrow "TF_VAR_twitter_consumer_secret"
        twitterAccessToken <- getEnvarOrThrow "TF_VAR_twitter_access_token"
        twitterAccessTokenSecret <- getEnvarOrThrow "TF_VAR_twitter_access_token_secret"
        JsonConfig ({ targetHandles, messages }) <- readJsonConfig
        pure $ WaterbotConfig {
           twitterConsumerKey: twitterConsumerKey,
           twitterConsumerSecret: twitterConsumerSecret,
           twitterAccessToken: twitterAccessToken,
           twitterAccessTokenSecret: twitterAccessTokenSecret,
           targetHandles: targetHandles,
           messages: messages
       }
