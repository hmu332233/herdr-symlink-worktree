# Symlink Worktree (herdr 플러그인)

새 git 워크트리가 생성될 때, 원본 repo 루트의 `.herdr-worktree-links`에 적힌
경로들을 새 워크트리로 자동 심볼릭 링크하는 플러그인.

워크트리는 별도 디렉터리라 gitignore된 `node_modules`, `.env`, 빌드 산출물 등이
빠진다. 매번 손으로 채우는 대신, 워크트리 생성 시 원본을 가리키는 심볼릭을 자동으로
걸어 부트스트랩을 끝낸다.

## 요구사항

- `PATH`에 `jq` (macOS/Linux). 없으면 조용히 skip.
- herdr `>= 0.7.0`.

## 설치 (로컬)

```sh
herdr plugin link /path/to/my-herdr-symlink-worktree
```

로컬 전용. GitHub 배포 안 함.

## repo 설정 (옵트인)

**원본 repo 루트**에 `.herdr-worktree-links` 생성. 한 줄에 하나, repo 루트 기준
상대경로. `#` 주석과 빈 줄은 무시.

```text
# 원본 repo 루트 기준 상대경로, 한 줄에 하나
.env
.env.local
node_modules
```

이 파일이 있는 repo에서만 동작. 없는 repo의 워크트리엔 무영향.

설정 파일은 커밋하지 말고 로컬 제외:

```sh
echo ".herdr-worktree-links" >> .git/info/exclude
```

## 동작

`.herdr-worktree-links`의 각 항목마다:

- `src = <원본repo>/<항목>`, `dest = <워크트리>/<항목>`.
- 소스 없음 -> skip (stderr).
- dest 이미 존재 (실파일이든 심볼릭이든) -> skip + 충돌 카운트 (stderr).
  기존 파일 절대 덮어쓰지 않음.
- 그 외 -> 부모 디렉터리 `mkdir -p` 후 `ln -s src dest`.

중첩 경로 허용 (부모 디렉터리 자동 생성). 절대경로와 `..` 세그먼트는 repo 탈출로
거부.

### 원칙

- **항상 exit 0.** 충돌·에러는 stderr 기록만 — herdr 이벤트 로그가 Failed로
  더럽혀지지 않음.
- **멱등성.** dest 존재 시 skip이라 같은 워크트리 재실행해도 안전 (중복 항목도
  두 번째는 skip).
- **옵트인.** 설정 파일 없으면 무동작.

## 파일 구조

```
my-herdr-symlink-worktree/
  herdr-plugin.toml   # 플러그인 매니페스트, worktree.created 훅
  link.sh             # 훅 스크립트
  README.md           # 영문
  README.ko.md        # 한글
```

## 검증 (수동)

1. 이 디렉터리를 `herdr plugin link`.
2. 테스트 repo에 `.herdr-worktree-links` 작성 + `.git/info/exclude`에 추가.
   적은 소스들이 실제 존재하는지 확인.
3. 워크트리 생성.
4. `herdr plugin log list --plugin dev.minung.symlink-worktree` — 실행 로그/요약 확인.
5. `ls -la <worktree>` — 심볼릭 생성 확인.
6. 케이스 점검: 충돌(dest 존재), 소스 없음, 설정 없는 repo(무동작), 중첩 경로.

## 범위 밖 (추후)

- 수동 `relink` 액션 (이벤트 훅만).
- GitHub 배포 / Windows / `jq` 없는 환경 폴백.
- stale 심볼릭 감지 / 자가치유.
- config 디렉터리 기반 전역 기본값.
