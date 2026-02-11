import boto3

s3 = boto3.client(
    "s3",
    endpoint_url="http://localhost:9000",
    aws_access_key_id="minioadmin",
    aws_secret_access_key="minioadmin",
)

bucket_name = "ml-artifacts"

# 버킷 생성 (이미 있으면 무시)
try:
    s3.create_bucket(Bucket=bucket_name)
    print(f"Bucket '{bucket_name}' created.")
except s3.exceptions.BucketAlreadyOwnedByYou:
    print(f"Bucket '{bucket_name}' already exists.")

# 파일 업로드
s3.put_object(
    Bucket=bucket_name,
    Key="models/v1/model.txt",
    Body=b"dummy model weights",
)
print("Upload complete: models/v1/model.txt")

# 파일 목록 조회
response = s3.list_objects_v2(Bucket=bucket_name)
print("\nFiles in bucket:")
for obj in response.get("Contents", []):
    print(f"  {obj['Key']} ({obj['Size']} bytes)")
