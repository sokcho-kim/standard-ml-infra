# 01. Terraform - Infrastructure as Code

## Why this tool?

기존에는 수동으로 서버를 생성하여 설정 누락이 잦았으나,
**Terraform**을 도입해 인프라 생성을 코드화하고 재현성을 확보한다.

### 핵심 개념 3가지

| 개념 | 설명 |
|------|------|
| **State** | Terraform이 관리하는 인프라의 현재 상태. `terraform.tfstate` 파일로 관리되며, 원격 백엔드(S3 등)에 저장하는 것이 팀 협업의 기본 |
| **Provider** | AWS, GCP, Azure 등 인프라 플랫폼과의 연결 고리. 어떤 클라우드를 쓸지 선언하는 부분 |
| **Module** | 반복되는 인프라 패턴을 재사용 가능한 단위로 묶은 것. 팀 표준을 모듈로 만들면 일관성 확보 가능 |

## How to use

### 사전 준비

```bash
# Terraform 설치 (macOS)
brew install terraform

# AWS CLI 설정
aws configure
```

### 실행

```bash
cd 01-terraform/

# 초기화: Provider 플러그인 다운로드
terraform init

# 변경 사항 미리 보기
terraform plan

# 인프라 생성
terraform apply

# 인프라 삭제
terraform destroy
```

## 파일 구조

```text
01-terraform/
├── main.tf          # 메인 리소스 정의
├── variables.tf     # 입력 변수 정의
├── outputs.tf       # 출력 값 정의
├── provider.tf      # Provider 설정
└── README.md
```

## Lessons Learned

### 1. State 파일은 절대 git에 커밋하지 않는다
- `terraform.tfstate`에는 리소스 ID, IP, 심지어 DB 비밀번호까지 평문으로 들어간다
- `.gitignore`에 `*.tfstate*` 반드시 추가
- 팀 협업 시에는 S3 + DynamoDB(Lock)를 백엔드로 설정해야 동시 수정 충돌 방지 가능

### 2. `plan` 없이 `apply` 하면 사고난다
- `terraform plan`은 "이렇게 바꿀 건데 괜찮냐?"를 보여주는 단계
- 특히 `destroy` 가 포함된 변경(예: 인스턴스 타입 변경 → 기존 인스턴스 삭제 후 재생성)은 plan에서 반드시 확인
- **습관**: `apply` 전에 항상 `plan` 먼저. CI/CD에서도 plan → 승인 → apply 파이프라인 구성

### 3. Provider 버전 고정은 필수
- `version = "~> 5.0"` 처럼 버전을 고정하지 않으면, 팀원마다 다른 버전이 설치되어 동작이 달라질 수 있다
- `terraform init` 시 생성되는 `.terraform.lock.hcl`은 lock 파일 역할 → git에 커밋해도 됨 (tfstate와 다름!)

### 4. 리소스 이름 태깅은 팀 표준의 시작
- `Name`, `Owner`, `Project` 태그를 일관되게 붙여야 "이 서버 누가 만들었지?" 사태를 방지
- 비용 추적도 태그 기반으로 하기 때문에, 처음부터 태그 규칙을 정하는 게 중요

### 5. 무료/저사양 환경에서의 주의점
- AWS Free Tier는 `t2.micro`만 무료. `t3.medium`은 과금됨
- `terraform destroy`를 안 하고 퇴근하면 다음 날 과금 폭탄
- 실습 후에는 반드시 `terraform destroy`로 리소스 정리
