echo "Building Purescript Code"
./scripts/build.sh

echo "Loading Environment Variables"
export $(cat .env | xargs)

echo "Validating"
sam validate -t sam.yaml --region $AWS_REGION

export DOCKER_HOST="unix://$HOME/.colima/docker.sock"

echo "Invoking"
sam local invoke PurescriptLambda -t sam.yaml --region $AWS_REGION \
--parameter-overrides \
ParameterKey=TF_VAR_twitter_consumer_key,ParameterValue=$TF_VAR_twitter_consumer_key \
ParameterKey=TF_VAR_twitter_consumer_secret,ParameterValue=$TF_VAR_twitter_consumer_secret \
ParameterKey=TF_VAR_twitter_access_token,ParameterValue=$TF_VAR_twitter_access_token \
ParameterKey=TF_VAR_twitter_access_token_secret,ParameterValue=$TF_VAR_twitter_access_token_secret\


