module OAuth (getAuthorizationHeader, getOAuthSignature, OAuthCredentials, RequestParameters) where

import Prelude

import Data.HTTP.Method (Method(..), print)
import Data.Map (Map, lookup, keys)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Array
import Data.Show
import Data.Ord (compare)
import Data.Boolean
import Data.Number.Format (toString)
import Data.Eq
import Data.Either (Either(..))
import Data.String
import Data.String.Regex as RGX
import Data.String.Regex.Flags
import Data.Int (toNumber, ceil)
import JSURI (encodeURIComponent)
import Data.Foldable (foldl)
import Node.Buffer as Buffer
import Node.Encoding
import Node.Crypto (randomBytes)
import Node.Crypto.Hmac
import Effect (Effect)
import Effect.Exception (try, Error, error, throw)
import Effect.Now
import Data.DateTime.Instant
import Data.Time.Duration


data ParamPair = ParamPair String String

instance paramPairEq :: Eq ParamPair where
    eq
        (ParamPair ka va)
        (ParamPair kb vb) =
            ka == kb && va == vb

instance paramPairOrd :: Ord ParamPair where
    compare
            (ParamPair ka _)
            (ParamPair kb _) = compare ka kb

type OAuthCredentials = {
    consumerKey :: String,
    consumerSecret :: String,
    accessToken :: String,
    accessTokenSecret :: String
}

type OAuthNonce = String

type OAuthTimestamp = Int

type RequestParameters = {
    method :: Method,
    -- The base URL is the URL to which the request is directed,
    -- minus any query string or hash parameters. It is important
    -- to use the correct protocol here, so make sure that the
    -- “https://” portion of the URL matches the actual request sent
    -- to the API.
    baseUrl :: String,
    -- All of the parameters included in the request. There are
    -- two such locations for these additional parameters -
    -- the URL (as part of the query string) and the request body.
    -- An HTTP request has parameters that are URL encoded, but
    -- you should collect the raw values.
    parameters :: Map String String
}

percentEncodeStr :: String -> Maybe String
percentEncodeStr s = encodeURIComponent s

getEncodedParamPair :: ParamPair -> Maybe ParamPair
getEncodedParamPair (ParamPair k v) = do
    encodedKey <- percentEncodeStr k
    encodedValue <- percentEncodeStr v
    pure $ ParamPair encodedKey encodedValue

getParamPairString :: ParamPair -> String
getParamPairString (ParamPair k v) = k <> "=" <> v

getParamStringFromSortedEncodedParams :: Array ParamPair -> String
getParamStringFromSortedEncodedParams xs =
    let
        pairs = getParamPairString <$> xs
    in
        joinWith "&" pairs


sortEncodedPairs :: Array ParamPair -> Array ParamPair
sortEncodedPairs xs = sort xs

paramPairsFromUrlParams :: Map String String -> Array ParamPair
paramPairsFromUrlParams m =
    foldl (\arr key ->
                    case lookup key m of
                        Just v -> snoc arr (ParamPair key v)
                        Nothing -> arr
            ) [] (keys m)

type SigningKey = String
type SigningString = String

data SigningComponents = SigningComponents SigningKey SigningString

getSigningComponents :: OAuthCredentials -> RequestParameters -> OAuthNonce -> OAuthTimestamp -> Maybe SigningComponents
getSigningComponents credentials request nonce ts = do
    defaultPairs :: Array ParamPair <- pure [
        ParamPair "oauth_consumer_key" credentials.consumerKey,
        ParamPair "oauth_nonce" nonce,
        ParamPair "oauth_signature_method" "HMAC-SHA1",
        ParamPair "oauth_timestamp" (toString $ toNumber ts),
        ParamPair "oauth_version" "1.0",
        ParamPair "oauth_token" credentials.accessToken
    ]
    paramPairs <- pure $ concat [defaultPairs, paramPairsFromUrlParams request.parameters]
    encodedPairs <- pure $ mapMaybe getEncodedParamPair paramPairs
    sortedPairs <- pure $ sortEncodedPairs encodedPairs
    paramString <- pure $ getParamStringFromSortedEncodedParams sortedPairs
    methodString <- pure $ print $ Left POST
    encodedUrl <- percentEncodeStr request.baseUrl
    encodedParamString <- percentEncodeStr paramString
    encodedConsumerSecret <- percentEncodeStr credentials.consumerSecret
    encodedTokenSecret <- percentEncodeStr credentials.accessTokenSecret
    signingKey <- pure $ encodedConsumerSecret <> "&" <> encodedTokenSecret
    baseString <- pure $ methodString <> "&" <> encodedUrl <> "&" <> encodedParamString
    pure $ SigningComponents signingKey baseString

-- Based on https://developer.twitter.com/en/docs/authentication/oauth-1-0a/creating-a-signature
getOAuthSignature :: OAuthCredentials -> RequestParameters -> OAuthNonce -> OAuthTimestamp -> Effect String
getOAuthSignature credentials request nonce ts = do
    (SigningComponents key payload) <- case getSigningComponents credentials request nonce ts of
                    Just c -> pure c
                    Nothing -> throw "Could not generate signing components"
    bufferKey <- Buffer.fromString key UTF8
    bufferPayload <- Buffer.fromString payload UTF8
    hmac <- createHmac "sha1" bufferKey
    hmacUpdate <- update bufferPayload hmac
    digestedValue <- digest hmacUpdate
    unencodedResult <- Buffer.toString Base64 digestedValue
    encodedResult <- pure $ percentEncodeStr unencodedResult
    case encodedResult of
        Just r -> pure r
        Nothing -> throw "Could not percent encode oauth signature"


getNonce :: Effect String
getNonce = do
    bytes <- randomBytes 11
    rawString <- Buffer.toString Base64 bytes
    replaceRegex <- pure $ RGX.regex "\\+|/|=" global
    case replaceRegex of
        Left err -> throw err
        Right rgx -> pure $ RGX.replace rgx "" rawString


currentTimetamp :: Effect Int
currentTimetamp = do
    instant <- now
    (Milliseconds m) <- pure $ unInstant instant
    pure $ ceil $ m / 1000.0

getAuthorizationHeader :: OAuthCredentials -> RequestParameters -> Maybe OAuthTimestamp -> Maybe OAuthNonce -> Effect String
getAuthorizationHeader credentials request ts n = do
    nonce <- case n of
                Just non -> pure non
                Nothing -> getNonce
    timestamp <- case ts of
                    Just t -> pure t
                    Nothing -> currentTimetamp
    signature <- getOAuthSignature credentials request nonce timestamp
    pure $ "OAuth oauth_consumer_key=\""
            <> credentials.consumerKey <>
            "\",oauth_token=\""
            <> credentials.accessToken <>
            "\",oauth_signature_method=\"HMAC-SHA1\",oauth_timestamp=\""
            <> (toString $ toNumber timestamp) <>
            "\",oauth_nonce=\""
            <> nonce <>
            "\",oauth_version=\"1.0\",oauth_signature=\""
            <> signature <> "\""