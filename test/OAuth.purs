module Test.Spec.OAuth where

import Prelude

import Data.Unit (Unit)
import Effect (Effect)
import Effect.Aff (launchAff_, delay)
import Test.Spec (pending, describe, it, Spec)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (runSpec)
import Data.HTTP.Method (Method(..))
import Data.Map (empty, singleton, fromFoldable)
import Data.Maybe (Maybe(..))
import Data.Either (Either(..))
import Data.Tuple
import Effect.Unsafe

import OAuth (getOAuthSignature, RequestParameters, OAuthCredentials)

spec :: Spec Unit
spec =
    describe "OAuth" do
        describe "getOAuthSignature" do
            it "should return a correctly generated signature" do
                result <- pure $ unsafePerformEffect $ getOAuthSignature
                            {
                                consumerKey: "xvz1evFS4wEEPTGEFPHBog",
                                consumerSecret: "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw",
                                accessToken: "370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb",
                                accessTokenSecret: "LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE"
                            }
                            {
                                method: POST,
                                baseUrl: "https://api.twitter.com/1.1/statuses/update.json",
                                parameters: fromFoldable [
                                    Tuple "status" "Hello Ladies + Gentlemen, a signed OAuth request!",
                                    Tuple "include_entities" "true"
                                ]
                            }
                            "kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg"
                            1318622958
                shouldEqual result "hCtSmYh+iHYCEqBWrE7C7hYmtUk="