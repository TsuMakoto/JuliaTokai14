# AWSアカウントセットアップ

- [サインアップ](https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=header_signup&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation&language=ja_jp#/account)

- [IAMユーザーの追加](https://us-east-1.console.aws.amazon.com/iamv2/home#/users/create)

awsのアクセスIDと、アクセスkeyを取得

- awscliインストール

- `aws configure`でawsのアクセスIDと、アクセスkeyを設定、regionはus-west-2が一番安い

- アカウントIDを右上のユーザー名からコピーしておく(scripts実行のときに利用)

# api作成

```
$ chmod +x scripts/create.sh
$ AWS_ACCOUNT_ID={コピーしたアカウントID} ./scripts/create
```

# api削除
```
$ chmod +x scripts/delete.sh
$ AWS_ACCOUNT_ID={コピーしたアカウントID} ./scripts/delete
```
