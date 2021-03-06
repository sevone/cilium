// Code generated by private/model/cli/gen-api/main.go. DO NOT EDIT.

package ec2

import (
	"context"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/internal/awsutil"
	"github.com/aws/aws-sdk-go-v2/private/protocol"
	"github.com/aws/aws-sdk-go-v2/private/protocol/ec2query"
)

type DeleteSecurityGroupInput struct {
	_ struct{} `type:"structure"`

	// Checks whether you have the required permissions for the action, without
	// actually making the request, and provides an error response. If you have
	// the required permissions, the error response is DryRunOperation. Otherwise,
	// it is UnauthorizedOperation.
	DryRun *bool `locationName:"dryRun" type:"boolean"`

	// The ID of the security group. Required for a nondefault VPC.
	GroupId *string `type:"string"`

	// [EC2-Classic, default VPC] The name of the security group. You can specify
	// either the security group name or the security group ID.
	GroupName *string `type:"string"`
}

// String returns the string representation
func (s DeleteSecurityGroupInput) String() string {
	return awsutil.Prettify(s)
}

type DeleteSecurityGroupOutput struct {
	_ struct{} `type:"structure"`
}

// String returns the string representation
func (s DeleteSecurityGroupOutput) String() string {
	return awsutil.Prettify(s)
}

const opDeleteSecurityGroup = "DeleteSecurityGroup"

// DeleteSecurityGroupRequest returns a request value for making API operation for
// Amazon Elastic Compute Cloud.
//
// Deletes a security group.
//
// If you attempt to delete a security group that is associated with an instance,
// or is referenced by another security group, the operation fails with InvalidGroup.InUse
// in EC2-Classic or DependencyViolation in EC2-VPC.
//
//    // Example sending a request using DeleteSecurityGroupRequest.
//    req := client.DeleteSecurityGroupRequest(params)
//    resp, err := req.Send(context.TODO())
//    if err == nil {
//        fmt.Println(resp)
//    }
//
// Please also see https://docs.aws.amazon.com/goto/WebAPI/ec2-2016-11-15/DeleteSecurityGroup
func (c *Client) DeleteSecurityGroupRequest(input *DeleteSecurityGroupInput) DeleteSecurityGroupRequest {
	op := &aws.Operation{
		Name:       opDeleteSecurityGroup,
		HTTPMethod: "POST",
		HTTPPath:   "/",
	}

	if input == nil {
		input = &DeleteSecurityGroupInput{}
	}

	req := c.newRequest(op, input, &DeleteSecurityGroupOutput{})
	req.Handlers.Unmarshal.Remove(ec2query.UnmarshalHandler)
	req.Handlers.Unmarshal.PushBackNamed(protocol.UnmarshalDiscardBodyHandler)

	return DeleteSecurityGroupRequest{Request: req, Input: input, Copy: c.DeleteSecurityGroupRequest}
}

// DeleteSecurityGroupRequest is the request type for the
// DeleteSecurityGroup API operation.
type DeleteSecurityGroupRequest struct {
	*aws.Request
	Input *DeleteSecurityGroupInput
	Copy  func(*DeleteSecurityGroupInput) DeleteSecurityGroupRequest
}

// Send marshals and sends the DeleteSecurityGroup API request.
func (r DeleteSecurityGroupRequest) Send(ctx context.Context) (*DeleteSecurityGroupResponse, error) {
	r.Request.SetContext(ctx)
	err := r.Request.Send()
	if err != nil {
		return nil, err
	}

	resp := &DeleteSecurityGroupResponse{
		DeleteSecurityGroupOutput: r.Request.Data.(*DeleteSecurityGroupOutput),
		response:                  &aws.Response{Request: r.Request},
	}

	return resp, nil
}

// DeleteSecurityGroupResponse is the response type for the
// DeleteSecurityGroup API operation.
type DeleteSecurityGroupResponse struct {
	*DeleteSecurityGroupOutput

	response *aws.Response
}

// SDKResponseMetdata returns the response metadata for the
// DeleteSecurityGroup request.
func (r *DeleteSecurityGroupResponse) SDKResponseMetdata() *aws.Response {
	return r.response
}
