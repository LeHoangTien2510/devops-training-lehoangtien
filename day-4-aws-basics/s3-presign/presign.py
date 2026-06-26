import boto3
from botocore.exceptions import ClientError

def generate_presigned_url(bucket_name, object_name, expiration=300):
    """
    Tạo một presigned URL để download một file từ S3 bucket riêng tư
    :param bucket_name: tên bucket (string)
    :param object_name: tên file trên S3 (string)
    :param expiration: Thời gian sống của URL tính bằng giây (int)
    :return: Đường dẫn URL nếu thành công, ngược lại trả về None
    """
    # Khởi tạo s3 client
    s3_client = boto3.client('s3')
    
    try:
        # Sử dụng hàm generate_presigned_url của boto3
        response = s3_client.generate_presigned_url(
            'get_object',
            Params={
                'Bucket': bucket_name,
                'Key': object_name
            },
            ExpiresIn=expiration
        )
    except ClientError as e:
        print(f"Đã xảy ra lỗi: {e}")
        return None

    # Trả về đường link presigned URL
    return response

if __name__ == "__main__":

    BUCKET_NAME = "private-tien-9999" 
    OBJECT_NAME = "private.pdf"
    EXPIRATION_TIME = 300 # 5 phút
    
    print("--- Đang khởi tạo Presigned URL từ Boto3 ---")
    url = generate_presigned_url(BUCKET_NAME, OBJECT_NAME, EXPIRATION_TIME)
    
    if url:
        print("\n[THÀNH CÔNG] Đường link presigned URL của bạn (Hiệu lực trong 5 phút):")
        print(url)
        print("\nHãy copy link trên dán vào trình duyệt để chạy thử nhé!")
