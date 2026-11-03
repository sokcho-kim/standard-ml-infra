# 06. Image Registry - 내부 저장소와 폐쇄망 배포

## Why this tool?

쿠버네티스 매니페스트에 `nginx:1.27`이나 `oci://charts.example.com/foo`처럼 외부 주소를 적으면,
클러스터는 배포할 때마다 그 외부 저장소에서 이미지와 차트를 받는다.
개발 환경에서는 문제가 드러나지 않지만, 운영 환경에서는 아래 이유로 내부 저장소를 거치도록 구성한다.

### 「공식 저장소라 안전하다」가 부족한 이유

| 위험 | 내용 |
|------|------|
| 태그 변경 | 태그는 다시 붙일 수 있는 이름이다. 같은 `1.27`이라도 어제와 오늘 받은 이미지가 다를 수 있다 |
| 삭제·이전 | 제공처가 버전을 삭제하거나 저장소 주소를 이전하면 배포가 실패한다 |
| 받기 횟수 제한 | Docker Hub 등은 계정·IP별 pull 횟수를 제한한다. 노드가 많으면 재시작만으로 한도에 걸린다 |
| 계정 탈취·공급망 공격 | 공식 저장소라도 배포 계정이 탈취되면 악성 이미지가 같은 이름으로 올라온다 |
| 망분리 | 공공·금융 운영망은 인터넷이 차단된 경우가 많다. 이 경우 외부 저장소는 선택지가 아니라 접근 자체가 불가능하다 |

즉 「출처가 공식인가」와 「배포 시점마다 같은 결과가 재현되는가」는 별개의 질문이다.
내부 저장소는 두 번째 질문에 답하기 위한 장치다.

### 핵심 개념

| 개념 | 설명 |
|------|------|
| **Registry** | 컨테이너 이미지(OCI 아티팩트)를 저장하는 서버. Docker Hub, GHCR, Harbor, `registry:2` 등 |
| **OCI 차트** | Helm 차트도 이미지와 같은 OCI 형식으로 레지스트리에 저장한다(`oci://…`) |
| **Tag** | 사람이 읽는 이름. 다시 붙일 수 있다(mutable) |
| **Digest** | 내용의 해시(`sha256:…`). 내용이 바뀌면 값도 바뀐다(immutable) |
| **Mirror** | 외부 이미지를 내부 레지스트리로 복사해 두는 방식 |
| **Proxy cache** | 내부 레지스트리가 요청을 대신 받아 외부에서 가져오고, 받은 것을 저장해 두는 방식 |
| **Air-gap(폐쇄망)** | 외부와 연결이 끊긴 환경. 파일로 반입하는 방식만 가능하다 |

### 세 가지 방식 비교

| 방식 | 외부 접속 필요 위치 | 관리 부담 | 적합한 경우 |
|------|------------------|----------|-----------|
| 미러링(목록 기반 복사) | 미러링 작업을 돌리는 곳(CI 등) | 목록 관리 필요. 자동화하면 낮음 | 버전을 명시적으로 고정해야 하는 납품·운영 환경 |
| 프록시 캐시 | 내부 레지스트리 서버 | 낮음. 처음 받을 때 자동 저장 | 내부 레지스트리는 외부에 나갈 수 있고 노드만 막힌 환경 |
| 오프라인 반입 | 반입 파일을 만드는 외부 PC | 높음. 매번 파일 반입 | 레지스트리 서버도 외부 접속이 불가능한 완전 폐쇄망 |

프록시 캐시는 편하지만 「처음 요청된 것을 그대로 저장」하므로 무엇이 들어왔는지 목록이 남지 않는다.
버전을 문서로 증명해야 하는 환경에서는 미러링과 digest 고정을 함께 쓴다.

## How to use

로컬에 내부 레지스트리를 하나 띄우고, 외부 이미지와 차트를 복사한 뒤 digest로 고정하는 흐름을 실습한다.

### 사전 준비

```bash
brew install crane helm   # crane: 이미지 복사·조회 도구 (go-containerregistry)
docker run -d --name local-registry -p 5000:5000 registry:2
```

### 1. 이미지 미러링

```bash
# 외부 → 내부 복사 (레이어 그대로, 다시 빌드하지 않음)
crane copy nginx:1.27 localhost:5000/mirror/nginx:1.27

# 내부 저장소의 digest 확인
crane digest localhost:5000/mirror/nginx:1.27
# sha256:…
```

### 2. 차트 미러링 (OCI)

```bash
helm pull oci://ghcr.io/stefanprodan/charts/podinfo --version 6.7.1
helm push podinfo-6.7.1.tgz oci://localhost:5000/charts --plain-http
```

### 3. digest로 고정

```yaml
# deployment.yaml — 태그 대신 digest
containers:
  - name: web
    image: localhost:5000/mirror/nginx@sha256:<위에서 확인한 값>
```

kustomize를 쓰면 `images`에서 digest를 지정할 수 있다.

```yaml
images:
  - name: nginx
    newName: localhost:5000/mirror/nginx
    digest: sha256:<위에서 확인한 값>
```

### 4. 노드가 내부 레지스트리를 보게 하기

매니페스트의 이미지 주소를 바꾸지 않고, 노드의 containerd가 외부 주소 요청을 내부 레지스트리로 돌리도록 설정할 수도 있다.
RKE2 예시는 [`registries.yaml`](registries.yaml)에 있다.

### 5. 완전 폐쇄망 반입

```bash
# 외부 PC: 파일로 저장
crane pull nginx:1.27 nginx-1.27.tar
helm pull oci://ghcr.io/stefanprodan/charts/podinfo --version 6.7.1

# 반입 후 내부 PC: 내부 레지스트리에 올림
crane push nginx-1.27.tar registry.internal/mirror/nginx:1.27
helm push podinfo-6.7.1.tgz oci://registry.internal/charts
```

반입 파일의 digest를 반입 전후로 비교해 기록한다.

### 정리

```bash
docker rm -f local-registry
```

## 파일 구조

```text
06-image-registry/
├── registries.yaml  # RKE2 노드의 레지스트리 미러 설정 예시
└── README.md
```

## Lessons Learned

### 1. 사내 GitHub 조직 저장소의 위치
- GHCR(`ghcr.io/<조직>`)에 미러링해 두면 출처는 통제되지만, 위치는 여전히 인터넷이다
- 운영망이 인터넷 차단이면 GHCR로도 받지 못한다
- 「내부 저장소」를 말할 때는 먼저 어느 망 안에 있는 저장소인지 확인한다

### 2. 미러링 자동화
- 버전 목록 파일 하나(예: `versions.yaml`)를 기준으로, CI가 차트·이미지를 복사하고 매니페스트의 태그까지 갱신하도록 구성한다
- 사람은 목록 파일만 수정하고 PR로 리뷰한다. 수동 복사가 없어져 실수와 귀찮음이 함께 줄어든다
- 이미지는 빠지고 차트만 미러링되는 식으로 목록이 반쪽이 되기 쉬우니, 차트가 참조하는 이미지까지 목록에 포함한다

### 3. 태그 고정과 digest 고정의 차이
- `1.27`처럼 버전 태그를 명시해도 내용이 바뀌는 것은 막지 못한다
- 납품·감사에서 「이 버전이 배포되었다」를 증명하려면 digest를 기록한다
- 사람이 읽기 위한 태그와 기계가 확인하는 digest를 함께 남기는 것이 실무적인 절충이다

### 4. 차트 내부 이미지 주소
- 차트를 내부로 옮겨도 차트 `values`의 `image.registry`가 외부를 가리키면 노드는 외부로 나간다
- 차트마다 `global.imageRegistry` 같은 덮어쓰기 값이 있는지 확인하고 내부 주소로 지정한다
- `helm template`으로 렌더링한 결과에서 `image:` 줄만 모아 외부 주소가 남았는지 검사한다

```bash
helm template my-release ./chart -f values.yaml | grep -E '^\s*image:' | sort -u
```

### 5. 원칙 준수 비용의 시점
- 외부 저장소를 직접 보게 하면 당장은 편하지만, 망분리 환경으로 옮기는 순간 전부 다시 해야 한다
- 처음부터 내부 저장소 기준으로 매니페스트를 작성하면 개발·운영 환경 차이가 레지스트리 주소 하나로 줄어든다
