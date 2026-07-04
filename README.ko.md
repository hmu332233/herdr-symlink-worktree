# Symlink Worktree

Symlink Worktree는 [herdr](https://herdr.dev)에서 새 Git 워크트리를 만들 때
메인 체크아웃의 선택한 파일과 디렉터리를 새 워크트리로 공유하는 플러그인입니다.

`.env` 파일, 배포 설정, 빌드 캐시, 개발 전용 산출물처럼 Git에 커밋하지 않는 로컬
상태를 워크트리마다 다시 만들고 싶지 않을 때 사용합니다.

```text
new-worktree/.env          -> main-checkout/.env
new-worktree/.turbo        -> main-checkout/.turbo
```

## 빠른 시작

1. 플러그인을 설치하거나 link합니다.

   ```sh
   herdr plugin link /path/to/herdr-symlink-worktree
   ```

   GitHub에서 설치할 때는 다음 형태를 사용합니다.

   ```sh
   herdr plugin install hmu332233/herdr-symlink-worktree
   ```

2. 사용할 repo의 메인 체크아웃에 `.herdr-worktree-links`를 만듭니다.

   ```text
   .env
   .env.local
   .turbo
   .next/cache
   .vercel
   ```

3. 평소처럼 herdr로 워크트리를 만듭니다.

   herdr의 `worktree.created` 이벤트가 발생하면 플러그인이 메인 체크아웃의
   `.herdr-worktree-links`를 읽고, 새 워크트리에 같은 경로의 심볼릭 링크를
   만듭니다.

`.herdr-worktree-links`가 없는 repo에는 아무 작업도 하지 않습니다.

## 설정

`.herdr-worktree-links`는 한 줄에 repo 루트 기준 상대경로 하나를 적습니다. 빈
줄은 무시되고, `#` 뒤는 주석입니다.

```text
# 새 워크트리에서 공유할 로컬 환경과 개발 캐시
.env
.env.local
.turbo
.next/cache
.vercel
```

팀에서 같은 경로를 의도적으로 공유하려는 경우가 아니라면 이 파일은 로컬에만 두는
편이 안전합니다.

```sh
echo ".herdr-worktree-links" >> .git/info/exclude
```

## 동작 방식

- herdr의 `worktree.created` 이벤트에서 실행됩니다.
- 새 워크트리만 처리합니다. 기존 워크트리는 수정하지 않습니다.
- 대상 워크트리에 이미 파일, 디렉터리, 심볼릭 링크가 있으면 덮어쓰지 않습니다.
- 원본 경로가 없으면 건너뜁니다.
- 절대경로와 `..`를 포함한 경로는 거부합니다.
- 심볼릭 링크를 만들기 전에 필요한 상위 디렉터리를 생성합니다.
- 건너뜀이나 검증 실패가 있어도 정상 종료해 herdr 이벤트를 실패로 표시하지
  않습니다.

## 요구사항

- herdr `>= 0.7.0`
- macOS 또는 Linux
- `PATH`에서 실행 가능한 `jq`
- herdr로 생성한 Git 워크트리

`jq`가 없으면 herdr 이벤트를 실패시키지 않고 해당 실행을 건너뜁니다.

## 문제 해결

링크가 만들어지지 않는다면 다음을 확인하세요.

1. 플러그인이 설치되고 활성화되어 있는지 확인합니다.

   ```sh
   herdr plugin list
   ```

2. `jq`가 설치되어 있는지 확인합니다.

   ```sh
   jq --version
   ```

3. `.herdr-worktree-links`가 새 워크트리가 아니라 메인 체크아웃에 있는지
   확인합니다.

4. 플러그인 로그를 확인합니다.

   ```sh
   herdr plugin log list --plugin dev.minung.symlink-worktree
   ```

## 보안

이 플러그인은 로컬 사용자 권한으로 실행되며, 메인 체크아웃의 경로를 새 워크트리로
심볼릭 링크합니다. 특히 secret이나 큰 생성물 디렉터리가 있는 repo에서는
`.herdr-worktree-links` 내용을 검토한 뒤 사용하세요.

## 라이선스

MIT. [LICENSE](./LICENSE)를 참고하세요.
