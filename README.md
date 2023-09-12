# lambda-go-template
Go による Lambda 関数のベース・テンプレート

`go-lambda-template`の部分をプロジェクト名・関数名に置換して使用してください。

## 開発の流れ

1. [設計](#設計について)
2. [コード実装](#開発について)
3. [テスト実装](#テストについて)
4. [デプロイ](#デプロイについて)
5. [動作確認](#動作確認について)

## 設計について

Lambda関数の要件・仕様を整理して、実装内容を明確にします。

## 開発について

ローカル環境にGoが導入されている場合、ディレクトリをそのまま使用できます。
Docker環境を使用することも可能です。

### コード実装について

実行される処理は`/functions/main.go`に実装します。
以下サンプルです。

エントリポイントのmain関数と、Lambdaで実行する関数を実装します。

- [Go による Lambda 関数の構築 - AWS Lambda](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/lambda-golang.html)

``` go
package main

import (
	"context"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	response := events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       "\"Hello from Lambda(Go)!\"",
	}
	return response, nil
}

func main() {
	lambda.Start(handler)
}
```

- handler()
  Lambdaで実行する関数です。デプロイせずに単体テストできるようにも実行処理は単独した関数にしましょう。
- main()
   関数コードが実行されるエントリポイントです。`lambda.Start()`を追加することでLambda関数が実行されます。


## テストについて

Lambdaで実行する関数のhandler()を中心にテストを実装します。\
実際に実行されることを想定して、正しい結果になること確認していきます。

### 実行コマンド
`./...`を引数にして全モジュールのテストを実施します。
```bash
go test -v ./...
```

### カバレッジ

#### カバレッジ計測の流れ

1~4 を繰り返してカバレッジ結果（`make output-coverage`）が 100％に近づくようにテストを実装していきます。

1. `make coverage`: カバレッジを計測する。
2. `make output-coverage`: 各関数のカバレッジを確認する。
3. `make compile-coverage-html`: カバレッジ結果を HTML ファイルに出力する。出力された`coverage.html`をブラウザで開き、網羅できていない処理をブラウザ上で確認する。
4. 網羅できていない部分のテストコードを追加する。

#### 各コマンド詳細

| 名称                  | 内容                                                                |
| :-------------------- | :------------------------------------------------------------------ |
| coverage              | 全モジュールのカバレッジを計測します。                              |
| output-coverage       | 計測したカバレッジ結果を関数単位で出力します。                      |
| output-coverage-total | 上記カバレッジの合計%値を出力します。                               |
| compile-coverage-html | 上記カバレッジ結果を HTML ファイル（`coverage.html`）に出力します。 |

##### 実行例

```bash
make coverage
```

## デプロイについて

テストで動作・品質が確認できたら、AWS環境にデプロイします。

プログラムの量がそれほど大きくなく
AWSの上限に達しない(20MB以下)の場合は、
.zip ファイルアーカイブを使用してデプロイします。

以下デプロイ手順です。各操作のコマンドは`Makefile`に格納しています。

1. zipファイルを作成する
2. デプロイする

- [.zip ファイルアーカイブを使用して Go Lambda 関数をデプロイする](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/golang-package.html)

### zipファイルを作成する

`make create-zip`からzipファイルを作成します。

### コマンド実行例

``` bash 
  cd functions && \
  go mod tidy && \
  GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -tags lambda.norpc -o bootstrap main.go && \
  zip myFunction.zip ./bootstrap
```

### デプロイする

※以降の処理はAWS CLIを使用します。

AWS CLI を使用して .zip ファイルで関数を作成、更新します。

#### 関数を作成する

`make create-function`で関数を作成します。

関数名、ロール、環境変数（設定ファイル）はデフォルト値を指定する形になっています。\
個別に指定する場合は下記の引数を指定してください。

| 引数名        | 内容                      |
| ------------- | ------------------------- |
| function-name | 関数名を指定              |
| role          | 適用するロール(ARN)を指定      |
| envfile       | 環境変数（設定ファイル ） |

##### CLIコマンド実行例

直接CLIから関数を作成する場合は、`create-function`を実行します。

- [zip ファイルアーカイブを使用して Go Lambda 関数をデプロイする - AWS Lambda](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/golang-package.html)
- [create-function — AWS CLI 1.29.44 Command Reference](https://docs.aws.amazon.com/cli/latest/reference/lambda/create-function.html)

``` bash
aws lambda create-function --function-name myFunction \
--runtime provided.al2 --handler bootstrap \
--architectures arm64 \
--role arn:aws:iam::111122223333:role/lambda-ex \
--zip-file fileb://myFunction.zip
```

#### 関数を更新する

`make update-function`で関数を更新します。

##### CLIコマンド実行例

直接CLIから関数を作成する場合は、`update-function-code`を実行して関数を更新します。

- [update-function-code — AWS CLI 1.29.44 Command Reference](https://docs.aws.amazon.com/cli/latest/reference/lambda/update-function-code.html)

``` bash
aws lambda update-function-code --function-name myFunction \
--zip-file fileb://myFunction.zip
```

#### 環境変数を更新

`make update-function-configuration`から環境変数のみ更新できます。

envfileにenvファイルを指定すると、指定ファイルの内容が環境変数に更新されます。

```sh
make update-function-configuration envfile=config/stg.env
```

##### CLIコマンド実行例

`update-function-configuration`を使用を実行して関数の各種設定を更新します。

環境変数以外にも各設定を更新することが可能です。

- [update-function-configuration — AWS CLI 1.29.44 Command Reference](https://docs.aws.amazon.com/cli/latest/reference/lambda/update-function-configuration.html)

```bash
aws lambda update-function-configuration --function-name myFunction \
	--timeout=300
```

## 動作確認について

デプロイ後は実装にAWS上で動作することを確認します。

### AWSコンソールから確認

1. AWSコンソールから対象関数を開く
1. テストタブを開く
1. 右上の「テスト」ボタンをクリックする
※パラメータがある場合はイベントJSONからリクエスト内容を指定する。

「実行中の関数: 成功」と表示されて、結果も想定する内容であればOKです。\
データの操作を行う関数の場合はログやDBを直接確認するのも忘れずに


### CLIから確認

`invoke`コマンドから関数を呼び出すことができます。


``` bash
% aws lambda invoke --function-name=myFunction response.json
```

実行結果は指定したファイルに保存されます。上記であれば`response.json`です。

``` bash
% cat response.json
{"statusCode":200,"headers":null,"multiValueHeaders":null,"body":"\"Hello from Lambda(Go)!\""}
```
- [invoke — AWS CLI 1.29.43 Command Reference](https://docs.aws.amazon.com/cli/latest/reference/lambda/invoke.html)
