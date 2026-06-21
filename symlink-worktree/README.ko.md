# Symlink Worktree (herdr 플러그인)

herdr가 새 git 워크트리를 생성할 때, 원본 repo 루트의 `.herdr-worktree-links`에
적힌 경로들을 새 워크트리로 자동 심볼릭 링크하는 플러그인.

워크트리는 별도 디렉터리라 gitignore된 `node_modules`, `.env`, 빌드 산출물 등이
빠진다. 매번 손으로 채우는 대신, 워크트리 생성 시 원본을 가리키는 심볼릭을 자동으로
걸어 부트스트랩을 끝낸다.

## 요구사항

- `PATH`에 `jq` (macOS/Linux). 없으면 조용히 skip.
- herdr `>= 0.7.0`.

## 설치 (로컬)

```sh
herdr plugin link /path/to/symlink-worktree
```

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

설정 파일은 커밋하지 말고 로컬 제외 — `.env` 같은 경로는 개인 환경이라 공용 설정으로
공유하면 안 됨:

```sh
echo ".herdr-worktree-links" >> .git/info/exclude
```

## 사용

설정만 끝내면, herdr로 워크트리를 만들 때 심볼릭이 자동 생성됨. 참고:

- **새** 워크트리에만 적용. 기존 워크트리엔 소급 적용 안 됨.
- dest에 이미 있는 파일은 절대 덮어쓰지 않음. 절대경로와 `..` 세그먼트는 거부.
- 모든 실행은 정상 종료라 실패가 조용함. 링크가 안 보이면 herdr 플러그인 로그 확인
  (그리고 `jq` 설치 여부 확인).
