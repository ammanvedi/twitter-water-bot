module OAuth where

import Data.HTTP.Method (Method(..), print)
import Data.Map (Map)

type OAuthCredentials = {
    "consumerKey" :: String,
    "consumerSecret" :: String,
    "accessToken" :: String,
    "accessTokenSecret" :: String
}


type RequestParameters = {
    "method" :: Method,
    -- The base URL is the URL to which the request is directed,
    -- minus any query string or hash parameters. It is important
    -- to use the correct protocol here, so make sure that the
    -- “https://” portion of the URL matches the actual request sent
    -- to the API.
    "baseUrl" :: String,
    -- All of the parameters included in the request. There are
    -- two such locations for these additional parameters -
    -- the URL (as part of the query string) and the request body.
    -- An HTTP request has parameters that are URL encoded, but
    -- you should collect the raw values.
    "parameters" :: Map String String
}

-- todo:
-- use https://pursuit.purescript.org/packages/purescript-crypto/5.0.1/docs/Node.Crypto.Hmac
-- finish impl based on https://developer.twitter.com/en/docs/authentication/oauth-1-0a/creating-a-signature
