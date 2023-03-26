#!/bin/bash

# lambda関数の定義
app_name="julia-lambda-app"
func_name=${app_name}-func

# APIGatewayの削除
aws apigateway delete-rest-api --rest-api-id $(aws apigateway get-rest-apis --query 'items[?name==`'${app_name}-api'`].id' --output text)

# lambda関数の削除
aws lambda delete-function --function-name $func_name

# policyの削除
aws iam delete-role-policy --role-name ${app_name}-role --policy-name ${app_name}-policy

# IAMロールの削除
aws iam delete-role --role-name ${app_name}-role

# ECRリポジトリの削除
aws ecr delete-repository --repository-name $app_name --force
