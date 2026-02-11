# 03. ArgoCD - GitOps Continuous Delivery

## Why this tool?

수동 `kubectl apply`는 "누가 언제 뭘 배포했는지" 추적이 안 된다.
**ArgoCD**를 도입하면 Git 레포가 Single Source of Truth가 되어,
코드 변경 → PR 머지 → 자동 배포의 GitOps 워크플로우를 구현할 수 있다.

### 핵심 개념

| 개념 | 설명 |
|------|------|
| **Application** | ArgoCD가 관리하는 배포 단위. Git 레포의 경로와 K8s 클러스터를 연결 |
| **Sync** | Git 상태와 클러스터 상태를 일치시키는 동작 |
| **Rollback** | 이전 Git 커밋 상태로 클러스터를 되돌리는 기능 |

## How to use

### 사전 준비

```bash
# ArgoCD 설치 (K8s 클러스터 필요)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# ArgoCD CLI 설치
brew install argocd

# 초기 비밀번호 확인
argocd admin initial-password -n argocd
```

### 실행

```bash
cd 03-gitops-argocd/

# Application 생성
kubectl apply -f application.yaml

# ArgoCD UI 접속
kubectl port-forward svc/argocd-server -n argocd 8080:443
# 브라우저에서 https://localhost:8080 접속
```

## 파일 구조

```text
03-gitops-argocd/
├── application.yaml  # ArgoCD Application 매니페스트
└── README.md
```

## Lessons Learned

### 1. GitOps의 핵심은 "Git = 유일한 진실"
- 클러스터 상태를 직접 `kubectl edit`으로 바꾸면 ArgoCD가 "OutOfSync" 감지
- `selfHeal: true` 설정 시 수동 변경을 자동으로 되돌림 → 실수 방지
- 모든 변경은 Git PR → 리뷰 → 머지로 진행해야 추적 가능

### 2. automated sync vs manual sync
- `automated`를 켜면 Git 변경 즉시 반영 → 개발 환경에 적합
- 운영 환경에서는 manual sync로 "배포 승인" 단계를 두는 것이 안전
- 처음 학습할 때는 automated로 시작하되, sync 과정을 UI에서 직접 눈으로 확인해볼 것

### 3. `prune: true`는 양날의 검
- Git에서 리소스 yaml을 삭제하면 클러스터에서도 자동 삭제됨
- 편리하지만 실수로 파일을 지웠을 때 운영 리소스가 날아갈 수 있음
- 운영 환경에서는 `prune: false`로 두고 수동 정리하는 팀도 많음

### 4. ArgoCD UI는 강력한 디버깅 도구
- 단순 배포 도구가 아니라 클러스터 리소스 상태를 시각적으로 보여줌
- Pod 로그, 이벤트, 리소스 트리를 UI에서 바로 확인 가능
- Sync 실패 시 어떤 리소스에서 에러가 났는지 한눈에 파악

### 5. Application yaml의 `path`가 핵심
- `source.path`에 Git 레포 내 어떤 폴더를 배포할지 지정
- 이 레포에서는 `02-kubernetes` 폴더를 소스로 연결함
- 폴더 구조를 잘 잡아두면 환경별(dev/staging/prod) Application을 path만 바꿔서 생성 가능
