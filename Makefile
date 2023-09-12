function-name = lambda-go-template
role = arn:aws:iam::111122223333:role/lambda-ex
envfile = config/dev.env
# テスト実行
test:
	cd functions
	go test ./... -coverprofile=coverage.out -coverpkg=./...
# カバレッジ結果出力
output-coverage:
	go tool cover -func=coverage.out
output-coverage-total:
	go tool cover -func=coverage.out | grep total | awk '{print $$3}'
# カバレッジ結果をHTML化
compile-coverage-html:
	go tool cover -html=coverage.out -o coverage.html
# テストのキャッシュを削除
clean-test-cache:
	cd functions && \
	go clean -testcache
# zipファイル作成
create-zip:
	cd functions && \
	go mod tidy && \
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -tags lambda.norpc -o bootstrap main.go && \
	zip main.zip ./bootstrap
# Lambda関数作成
create-function:
	VAR=$$(grep -o '^[^#]*' ${envfile} | tr '\n' ','); \
	aws lambda create-function \
	--function-name ${function-name} \
	--runtime provided.al2 --handler bootstrap  \
	--role ${role} \
	--zip-file fileb://functions/main.zip \
	--timeout 300 \
	--environment Variables="{"$${VAR}"}"
# Lambda関数更新
update-function:
	aws lambda update-function-code --function-name ${function-name} \
	--zip-file fileb://functions/main.zip
# 環境変数を更新
update-function-configuration:
	VAR=$$(grep -o '^[^#]*' ${envfile} | tr '\n' ','); \
	aws lambda update-function-configuration --function-name ${function-name} \
	--environment Variables="{"$${VAR}"}"