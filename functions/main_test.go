package main

import (
	"context"
	"reflect"
	"testing"

	"github.com/aws/aws-lambda-go/events"
)

type MoclContext context.Context

func Test_handler(t *testing.T) {
	type args struct {
		ctx   context.Context
		event events.APIGatewayProxyRequest
	}

	var ctx MoclContext
	tests := []struct {
		name    string
		args    args
		want    events.APIGatewayProxyResponse
		wantErr bool
	}{
		// TODO: Add test cases.
		{
			name: "return response",
			args: args{
				ctx:   ctx,
				event: events.APIGatewayProxyRequest{},
			},
			want: events.APIGatewayProxyResponse{
				StatusCode: 200,
				Body:       "\"Hello from Lambda(Go)!\"",
			},
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := handler(tt.args.ctx, tt.args.event)
			if (err != nil) != tt.wantErr {
				t.Errorf("handler() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("handler() = %v, want %v", got, tt.want)
			}
		})
	}
}
