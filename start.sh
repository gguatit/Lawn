#!/usr/bin/env bash

set -euo pipefail

device="/dev/urandom"
count="100"
file="README.md"
commit_msg=""

# 현재 브랜치
branch="$(git rev-parse --abbrev-ref HEAD)"

# 랜덤 값 생성: 바이트 단위 정수값(count 바이트 -> count 수치)
# od를 사용. /dev/random 대신 /dev/urandom 권장(블로킹 방지).
# 출력은 공백으로 구분된 한 줄로 만듦.
random_values="$(od -An -v -N"$count" -tu1 "$device" | tr -s ' \n' ' ' | sed 's/^ //; s/ $//')"

if [[ -z "$random_values" ]]; then
  echo "에러: 랜덤 값을 생성하지 못했습니다." >&2
  exit 1
fi

# 10번째 줄 교체 (awk 사용)
tmp="$(mktemp)"
awk -v new="$random_values" 'NR==10{$0=new} {print}' "$file" > "$tmp"
mv -- "$tmp" "$file"
echo "파일 업데이트: $file (3번째 줄을 $count개 값으로 교체)"

# git 단계
git add -- "$file"
# 변경사항이 있는지 확인 (비어있는 커밋 방지)
if git diff --cached --quiet -- "$file"; then
  echo "변경 사항 없음 — 커밋하지 않습니다."
  exit 0
fi

if [[ -z "$commit_msg" ]]; then
  commit_msg="$(git rev-parse HEAD)"
fi

git commit -m "$commit_msg"
echo "커밋 완료."

# 푸시
echo "현재 브랜치 '$branch' 에 푸시합니다..."
git push origin "$branch"
echo "푸시 완료."

exit 0
