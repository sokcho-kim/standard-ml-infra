# standard-ml-infra

MLOps 표준 인프라 구축을 위한 스터디 레포지토리

## 목표

각개전투로 흩어져 있던 ML 인프라 지식을 **하나의 표준**으로 정리하고, 실제 돌아가는 코드로 검증한다.

## 로드맵

| 단계 | 폴더 | 주제 | 핵심 키워드 |
|------|------|------|------------|
| 1 | `01-terraform/` | IaC: 인프라의 기본 | State, Provider, Module |
| 2 | `02-kubernetes/` | Orchestration: 클러스터 설정 | Pod, Service, Deployment |
| 3 | `03-gitops-argocd/` | CD: GitOps 기반 배포 | Application, Sync, Rollback |
| 4 | `04-artifact-minio/` | Storage: 데이터/모델 저장소 | Bucket, S3 API, Versioning |
| 5 | `05-experiment-mlflow/` | Tracking: 실험 추적 | Experiment, Run, Model Registry |
| 6 | `06-image-registry/` | Supply: 내부 저장소와 폐쇄망 배포 | Mirror, Proxy cache, Digest |

## 진행 방식

각 폴더의 README에는 다음 3가지를 반드시 기록한다:

1. **Why this tool?** - 도구 선택 이유와 기존 문제점
2. **How to use** - 클론 후 5분 안에 Hello World를 띄울 수 있는 가이드
3. **Lessons Learned** - 시행착오와 우리 환경에 맞는 인사이트

## 빠른 시작

```bash
git clone <this-repo>
cd standard-ml-infra

# 각 단계별 폴더로 이동하여 README 참고
cd 01-terraform/
```

## 참고

- 이 레포는 학습 + 팀 표준 제안 목적으로 만들어졌습니다.
- 각 단계는 독립적으로 실행 가능하지만, 순서대로 진행하는 것을 권장합니다.
