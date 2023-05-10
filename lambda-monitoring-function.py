import boto3
import os

def lambda_handler(event, context):
    bucket_name = os.environ.get('BUCKET_NAME')
    
    s3 = boto3.client('s3')
    response = s3.list_objects_v2(Bucket=bucket_name)
    
    total_objects = response['KeyCount']
    
    return {
        'statusCode': 200,
        'body': f'Total de objetos no bucket: {total_objects}'
    }