#!bin/bash

# lambda関数の定義
app_name="julia-lambda-app"
func_name=${app_name}-func

# IAM Roleの作成
# 信頼ポリシーで記載
aws iam create-policy \
  --policy-name ${app_name}-policy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:us-west-2:'${AWS_ACCOUNT_ID}':*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:us-west-2:'${AWS_ACCOUNT_ID}':log-group:/aws/lambda/'${func_name}':*"
            ]
        }
    ]
}'


# 信頼関係の作成
aws iam create-role --role-name ${app_name}-role --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}'

aws iam put-role-policy \
  --role-name ${app_name}-role \
  --policy-name ${app_name}-policy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:us-west-2:'${AWS_ACCOUNT_ID}':*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:us-west-2:'${AWS_ACCOUNT_ID}':log-group:/aws/lambda/'${func_name}':*"
            ]
        }
    ]
}'

aws iam create-instance-profile --instance-profile-name ${app_name}-role

# ECRリポジトリ作成
aws ecr create-repository --repository-name $app_name

# dockerビルド
docker build -t $app_name .

# tag付
docker tag ${app_name}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/${app_name}:latest

# ECRログイン
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com

# ECRにpush
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/${app_name}:latest

# lambda関数の作成
aws lambda create-function \
  --function-name $func_name \
  --package-type Image \
  --code ImageUri=${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/${app_name}:latest \
  --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/${app_name}-role \
  --timeout 60 \
  --memory-size 1024

# API作成
aws apigateway create-rest-api --name ${app_name}-api

# API IDの取得
api_id=$(aws apigateway get-rest-apis --query 'items[?name==`'${app_name}-api'`].id | [0]' --output text)

# リソースIDの取得
root_id=$(aws apigateway get-resources --rest-api-id $api_id --query 'items[?path==`/`].id | [0]' --output text)

# helloリソースの作成
aws apigateway create-resource \
  --rest-api-id $api_id \
  --parent-id $root_id \
  --path-part hello

# helloリソースのIDを取得
hello_id=$(aws apigateway get-resources --rest-api-id $api_id --query 'items[?path==`/hello`].id | [0]' --output text)

# リソースにメソッドを追加する
aws apigateway put-method \
  --rest-api-id $api_id \
  --resource-id $hello_id \
  --http-method GET \
  --authorization-type "NONE" \
  --no-api-key-required

# APIGateway ==> Lambda
aws lambda add-permission \
  --function-name $func_name \
  --statement-id apigateway \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-west-2:${AWS_ACCOUNT_ID}:$api_id/*/GET/hello"

# Lambda ==> APIGateway
aws apigateway put-integration \
  --rest-api-id $api_id \
  --resource-id $hello_id \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-2:${AWS_ACCOUNT_ID}:function:${func_name}/invocations

# デプロイ
aws apigateway create-deployment \
  --rest-api-id $api_id \
  --stage-name dev

