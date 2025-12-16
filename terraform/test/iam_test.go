package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Common test variables matching terraform.tfvars.example
var testTags = map[string]string{
	"Project":     "coinnode",
	"Environment": "test",
	"ManagedBy":   "terraform",
}

const testPath = "/coinnode/"

// TestIAMBasic tests basic deployment without user creation.
func TestIAMBasic(t *testing.T) {
	uniqueID := strings.ToLower(random.UniqueId())
	baseName := fmt.Sprintf("coinnode-%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"base_name":   baseName,
			"create_user": false,
			"path":        testPath,
			"tags":        testTags,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	roleArn := terraform.Output(t, terraformOptions, "role_arn")
	roleName := terraform.Output(t, terraformOptions, "role_name")
	policyArn := terraform.Output(t, terraformOptions, "policy_arn")
	groupName := terraform.Output(t, terraformOptions, "group_name")

	assert.True(t, strings.HasPrefix(roleArn, "arn:aws:iam::"), "Role ARN should have correct prefix")
	assert.True(t, strings.Contains(roleArn, ":role"+testPath), "Role ARN should contain path")
	assert.Contains(t, roleName, baseName, "Role name should contain base name")

	assert.True(t, strings.HasPrefix(policyArn, "arn:aws:iam::"), "Policy ARN should have correct prefix")
	assert.True(t, strings.Contains(policyArn, ":policy"+testPath), "Policy ARN should contain path")

	assert.Contains(t, groupName, baseName, "Group name should contain base name")

	// When create_user is false, user_arn output is null and won't exist in terraform output
	userArn, err := terraform.OutputE(t, terraformOptions, "user_arn")
	assert.True(t, err != nil || userArn == "", "User ARN should be empty or not exist when create_user is false")
}

// TestIAMWithUser tests deployment with user creation enabled.
func TestIAMWithUser(t *testing.T) {
	uniqueID := strings.ToLower(random.UniqueId())
	baseName := fmt.Sprintf("coinnode-%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"base_name":   baseName,
			"create_user": true,
			"path":        testPath,
			"tags":        testTags,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	userArn := terraform.Output(t, terraformOptions, "user_arn")
	userName := terraform.Output(t, terraformOptions, "user_name")

	assert.True(t, strings.HasPrefix(userArn, "arn:aws:iam::"), "User ARN should have correct prefix")
	assert.True(t, strings.Contains(userArn, ":user"+testPath), "User ARN should contain path")
	assert.Contains(t, userName, baseName, "User name should contain base name")
}

// TestIAMIdempotency tests that applying twice results in no changes.
func TestIAMIdempotency(t *testing.T) {
	uniqueID := strings.ToLower(random.UniqueId())
	baseName := fmt.Sprintf("coinnode-%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"base_name":   baseName,
			"create_user": true,
			"path":        testPath,
			"tags":        testTags,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.Init(t, terraformOptions)
	terraform.ApplyAndIdempotent(t, terraformOptions)
}
