import json
import boto3

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    # EventBridge sends structured JSON directly
    detail = event["detail"]

    token = detail['LifecycleActionToken']
    asg_name = detail['AutoScalingGroupName']
    instance_id = detail['EC2InstanceId']

    print(f"Processing termination of instance {instance_id} in ASG {asg_name}")

    # Step 1: Run SSM command to copy logs
    ssm = boto3.client('ssm')

    try:
        response = ssm.send_command(
            InstanceIds=[instance_id],
            DocumentName="CopyLogsToS3",  # Must match your Terraform SSM document
            TimeoutSeconds=60,
        )
        print(f"SSM command sent: {response['Command']['CommandId']}")
    except Exception as e:
        print(f"Error sending SSM command: {e}")

    # Step 2: Complete the lifecycle action
    autoscaling = boto3.client('autoscaling')
    autoscaling.complete_lifecycle_action(
        LifecycleHookName='terminate-logs',
        AutoScalingGroupName=asg_name,
        LifecycleActionToken=token,
        LifecycleActionResult='CONTINUE'
    )

    return {"status": "completed"}
