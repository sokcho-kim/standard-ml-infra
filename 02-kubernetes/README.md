# 02. Kubernetes - Container Orchestration

## Why this tool?

ML 워크로드는 학습/추론/전처리 등 다양한 작업이 동시에 돌아가야 한다.
**Kubernetes**를 사용하면 컨테이너 기반으로 리소스 할당, 스케일링, 헬스체크를 자동화할 수 있다.

### 핵심 개념

| 개념 | 설명 |
|------|------|
| **Pod** | K8s에서 배포할 수 있는 가장 작은 단위. 하나 이상의 컨테이너를 포함 |
| **Service** | Pod에 안정적인 네트워크 엔드포인트를 제공 |
| **Deployment** | Pod의 선언적 업데이트를 관리. 롤링 업데이트, 롤백 지원 |

## How to use

### 사전 준비

```bash
# kubectl 설치
brew install kubectl

# 로컬 클러스터 (minikube 또는 kind)
brew install minikube
minikube start
```

### 실행

```bash
cd 02-kubernetes/

# 리소스 생성
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# 상태 확인
kubectl get pods -n ml-standard
kubectl get svc -n ml-standard
```

## 파일 구조

```text
02-kubernetes/
├── namespace.yaml    # 네임스페이스 정의
├── deployment.yaml   # Deployment 매니페스트
├── service.yaml      # Service 매니페스트
└── README.md
```

## Lessons Learned

### 1. Pod은 직접 만들지 말고 Deployment로 만든다
- `kubectl run`이나 Pod yaml로 직접 만든 Pod은 죽으면 그대로 끝
- Deployment로 만들면 Pod이 죽어도 자동으로 다시 띄워준다 (self-healing)
- 직접 Pod을 만드는 경우는 디버깅용 일회성 작업 정도

### 2. resources 설정은 선택이 아니라 필수
- `requests`는 "최소 이만큼은 확보해줘", `limits`는 "이 이상은 쓰지 마"
- 설정 안 하면 한 Pod이 노드 전체 메모리를 먹어서 다른 Pod이 죽는 사태 발생
- ML 워크로드는 특히 메모리를 많이 쓰기 때문에 반드시 설정

### 3. namespace로 환경을 분리한다
- `default` 네임스페이스에 다 때려넣으면 나중에 정리 불가능
- `ml-standard`, `ml-dev`, `ml-prod` 식으로 분리하면 `kubectl delete ns ml-dev`로 한방 정리 가능
- RBAC(권한 관리)도 namespace 단위로 걸 수 있음

### 4. `kubectl describe`가 디버깅의 핵심
- Pod이 안 뜨면 `kubectl describe pod <이름> -n <ns>` 부터 확인
- Events 섹션에 "이미지 못 찾음", "리소스 부족", "스케줄링 실패" 등 원인이 다 나옴
- `kubectl logs <pod> -n <ns>`로 컨테이너 내부 로그 확인

### 5. minikube vs kind 선택
- **minikube**: VM 기반, 가장 대중적이지만 무겁다. `minikube start`로 간편 시작
- **kind**: Docker 컨테이너 기반, 가볍고 빠르다. CI/CD에서도 많이 사용
- 로컬 학습 용도로는 둘 다 충분하지만, M1/M2 Mac에서는 kind가 더 안정적인 경우 있음
