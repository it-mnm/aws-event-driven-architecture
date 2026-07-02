terraform {
  backend "s3" {
    bucket         = "mh-terraform-state-bucket-unique" 
    key            = "dev/terraform.tfstate"           # 버킷 내 장부 파일이 저장될 경로
    region         = "ap-northeast-2"                   # 서울 리전
    encrypt        = true                               # 장부 파일 암호화 활성화
    dynamodb_table = "mh-terraform-locks"               # 동시 수정 막기 위한 잠금 장치 테이블 (선택)
  }
}