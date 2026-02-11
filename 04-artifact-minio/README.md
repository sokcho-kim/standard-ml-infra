# 04. MinIO - Artifact Storage

## Why this tool?

ML 파이프라인에서 학습 데이터, 모델 파일, 피처 등을 체계적으로 저장/버전 관리해야 한다.
**MinIO**는 S3 호환 오브젝트 스토리지로, 온프레미스 환경에서도 S3 API를 그대로 사용할 수 있다.

### 핵심 개념

| 개념 | 설명 |
|------|------|
| **Bucket** | 오브젝트를 담는 최상위 컨테이너. 프로젝트/용도별로 분리 |
| **S3 API** | AWS S3와 동일한 API. boto3 등 기존 S3 클라이언트 코드를 그대로 사용 가능 |
| **Versioning** | 같은 키에 대해 여러 버전을 보관. 모델 파일 롤백에 유용 |

## How to use

### 사전 준비

```bash
# Docker로 MinIO 실행
docker run -d \
  --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  minio/minio server /data --console-address ":9001"

# MinIO Client 설치
brew install minio/stable/mc
mc alias set local http://localhost:9000 minioadmin minioadmin
```

### 실행

```bash
# 버킷 생성
mc mb local/ml-artifacts

# 파일 업로드 테스트
echo "hello minio" > test.txt
mc cp test.txt local/ml-artifacts/

# 파일 목록 확인
mc ls local/ml-artifacts/
```

### Python에서 사용

```bash
pip install boto3
python example_upload.py
```

## 파일 구조

```text
04-artifact-minio/
├── docker-compose.yaml   # MinIO 컨테이너 설정
├── example_upload.py     # Python 업로드 예제
└── README.md
```

## Lessons Learned

### 1. MinIO를 쓰는 이유: "클라우드 종속 탈출"
- AWS S3를 직접 쓰면 편하지만, 온프레미스(사내 서버)에서는 S3가 없음
- MinIO는 S3 API를 100% 호환 → boto3 코드를 **한 줄도 안 바꾸고** 로컬/클라우드 전환 가능
- `endpoint_url`만 바꾸면 됨. 코드 변경 없이 환경 전환이 가능한 게 핵심

### 2. docker-compose로 띄우는 게 가장 간편
- `docker run` 명령어는 길고 실수하기 쉬움
- `docker-compose up -d` 한 줄이면 끝. 설정도 yaml에 다 기록되어 재현 가능
- 볼륨(`minio_data`)을 연결해야 컨테이너 재시작해도 데이터가 살아남음

### 3. 버킷 네이밍 컨벤션을 정해두자
- `ml-artifacts`, `raw-data`, `feature-store` 식으로 용도별 분리
- 버킷 이름에 대문자, 언더스코어 사용 불가 (S3 규칙) → 하이픈(`-`) 사용
- 팀 표준 예시: `{프로젝트}-{용도}` → `recommend-model`, `recommend-rawdata`

### 4. 웹 콘솔(9001 포트)이 의외로 유용
- `http://localhost:9001`로 접속하면 GUI로 버킷/파일 관리 가능
- 파일 미리보기, 권한 설정, 버전 관리 등을 UI에서 바로 할 수 있음
- 처음 학습할 때는 CLI보다 웹 콘솔로 감 잡는 게 빠름

### 5. 운영 환경에서는 인증 정보를 환경변수로
- 예제 코드에 `minioadmin/minioadmin`이 하드코딩되어 있지만 이건 학습용
- 실제로는 `.env` 파일이나 K8s Secret으로 관리
- boto3는 `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` 환경변수를 자동으로 읽음
