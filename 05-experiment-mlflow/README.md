# 05. MLflow - Experiment Tracking

## Why this tool?

"어떤 하이퍼파라미터로 돌렸을 때 성능이 제일 좋았지?" 를 기억에 의존하면 안 된다.
**MLflow**를 도입하면 실험 파라미터, 메트릭, 모델 아티팩트를 체계적으로 추적하고 비교할 수 있다.

### 핵심 개념

| 개념 | 설명 |
|------|------|
| **Experiment** | 관련된 실험 Run들을 묶는 논리적 그룹 |
| **Run** | 하나의 학습 실행 단위. 파라미터, 메트릭, 아티팩트를 기록 |
| **Model Registry** | 학습된 모델의 버전 관리 및 스테이지(Staging/Production) 관리 |

## How to use

### 사전 준비

```bash
pip install mlflow scikit-learn
```

### MLflow 서버 실행

```bash
# 로컬 서버 실행 (MinIO를 아티팩트 저장소로 사용할 경우)
mlflow server \
  --host 0.0.0.0 \
  --port 5000 \
  --backend-store-uri sqlite:///mlflow.db \
  --default-artifact-root s3://ml-artifacts/mlflow

# 또는 간단하게 로컬 파일 기반으로 실행
mlflow ui --port 5000
```

### 실험 실행

```bash
cd 05-experiment-mlflow/
python train_example.py

# 브라우저에서 http://localhost:5000 접속하여 결과 확인
```

## 파일 구조

```text
05-experiment-mlflow/
├── train_example.py  # MLflow 로깅이 포함된 학습 예제
└── README.md
```

## Lessons Learned

### 1. MLflow의 두 가지 저장소를 구분하자
- **Backend Store**: 파라미터, 메트릭 등 메타데이터 저장 (SQLite, MySQL, PostgreSQL)
- **Artifact Store**: 모델 파일, 이미지 등 큰 파일 저장 (로컬, S3, MinIO)
- `mlflow ui`는 둘 다 로컬 파일에 저장. 팀 공유 시에는 서버 모드로 분리 필요

### 2. `mlflow ui` vs `mlflow server`
- `mlflow ui`: 로컬에서 혼자 쓸 때. `./mlruns` 폴더에 모든 게 저장됨
- `mlflow server`: 팀 공유용. DB + 오브젝트 스토리지를 백엔드로 설정
- 혼자 학습할 때는 `mlflow ui`로 충분하고, 나중에 서버로 전환

### 3. Experiment 이름을 체계적으로 짓자
- `Default` 실험에 다 넣으면 나중에 찾기 불가능
- `{프로젝트}-{모델}-{목적}` 식으로 네이밍: `recommend-xgboost-hyperparam-search`
- `mlflow.set_experiment("이름")` 한 줄이면 자동 분류

### 4. `autolog`를 쓰면 코드 변경 최소화
- `mlflow.sklearn.autolog()` 한 줄이면 파라미터, 메트릭, 모델을 자동 기록
- scikit-learn, PyTorch, TensorFlow, XGBoost 등 주요 프레임워크 지원
- 수동 로깅(`log_param`, `log_metric`)은 커스텀 메트릭이 필요할 때만

### 5. MinIO + MLflow 연동이 핵심 시나리오
- `04-artifact-minio`에서 띄운 MinIO를 MLflow의 아티팩트 저장소로 연결 가능
- `--default-artifact-root s3://ml-artifacts/mlflow` + MinIO endpoint 설정
- 이렇게 하면 모델 파일이 MinIO에 저장되어 팀원 누구나 접근 가능
- 환경변수 필요: `MLFLOW_S3_ENDPOINT_URL=http://localhost:9000`

### 6. Model Registry로 모델 배포 단계 관리
- 실험 Run에서 좋은 모델을 Registry에 등록
- `None` → `Staging` → `Production` 스테이지로 승격
- "지금 운영에 나가 있는 모델이 뭐지?"를 한눈에 파악 가능
