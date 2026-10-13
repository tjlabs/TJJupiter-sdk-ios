#!/usr/bin/env bash
#
# verify_vendored_symbols.sh
#
# 이 SDK는 `s.source_files`(소스)와 `s.vendored_frameworks`(바이너리 xcframework)를
# 함께 배포합니다. 소스(Classes/**)가 vendored 프레임워크의 타입에 대해 호출하는
# 메서드가, 실제로 번들된 xcframework의 .swiftinterface 에 존재하지 않으면
# 컨슈머 프로젝트에서만 다음과 같은 컴파일 에러가 납니다(SDK 자체 빌드는 통과):
#
#   Value of type '...' has no member 'startService'
#
# 이 스크립트는 릴리스 전에 그 불일치를 잡아냅니다. 소스에서 `<prefix><method>(`
# 호출을 추출해, 매핑된 프레임워크의 모든 .swiftinterface 에 각 메서드가 `func`로
# 선언되어 있는지 확인합니다. 누락이 하나라도 있으면 non-zero 로 종료합니다.
#
# 사용:  ./Scripts/verify_vendored_symbols.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLASSES_DIR="$ROOT/TJJupiterSDK/Classes"
FRAMEWORKS_DIR="$ROOT/TJJupiterSDK/Frameworks"

# 검증할 매핑: "<호출 prefix>:<vendored 프레임워크 이름>"
# prefix 뒤에 오는 `<method>(` 호출을 추출해 해당 프레임워크 인터페이스에서 검증한다.
#   - 인스턴스 호출 : serviceManager.  ->  (self.)serviceManager.<method>( 를 모두 커버
#   - 정적/타입 호출: TJLabsAuthConstants. , JupiterLogger.
#   - 싱글턴 호출   : TJLabsAuthManager.shared.
# 프로퍼티 접근(뒤에 '(' 없음)은 자연히 제외된다.
MAPPINGS=(
  "serviceManager.:TJLabsJupiter"
  "TJLabsAuthConstants.:TJLabsAuth"
  "TJLabsAuthManager.shared.:TJLabsAuth"
  "JupiterLogger.:TJLabsJupiter"
)

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
dim()   { printf '\033[2m%s\033[0m\n' "$1"; }

fail=0

for mapping in "${MAPPINGS[@]}"; do
  prefix="${mapping%:*}"
  framework="${mapping##*:}"
  xcframework="$FRAMEWORKS_DIR/$framework.xcframework"

  echo "==> ${prefix}<method>( 호출을 $framework.xcframework 에 대해 검증"

  if [[ ! -d "$xcframework" ]]; then
    red "  ✗ $xcframework 를 찾을 수 없습니다"
    fail=1
    continue
  fi

  # 검사 대상 .swiftinterface 수집 (private 인터페이스는 제외 — 컨슈머가 보는 것은 public)
  interfaces=()
  while IFS= read -r f; do interfaces+=("$f"); done < <(
    find "$xcframework" -name "*.swiftinterface" ! -name "*.private.swiftinterface" 2>/dev/null || true
  )
  if [[ ${#interfaces[@]} -eq 0 ]]; then
    red "  ✗ $framework 의 .swiftinterface 를 찾을 수 없습니다"
    fail=1
    continue
  fi

  # prefix를 정규식용으로 이스케이프('.' -> '\.')
  prefix_re="$(printf '%s' "$prefix" | sed -E 's/[.]/\\./g')"

  # 소스에서 <prefix><method>( 형태의 메서드 이름 추출 (프로퍼티 접근은 '(' 없어서 자연히 제외).
  # prefix 앞에 식별자 문자(alnum/_)가 오면 다른 타입의 접미사로 오탐되므로 경계를 둔다.
  # (예: prefix 'JupiterLogger.' 가 SDK 자체 'TJJupiterLogger.' 를 잡지 않도록.
  #  단, 'self.serviceManager.' 처럼 앞의 '.' 은 허용해야 인스턴스 호출이 잡힘)
  methods=()
  while IFS= read -r m; do methods+=("$m"); done < <(
    grep -rhoE "(^|[^a-zA-Z0-9_])${prefix_re}[a-zA-Z_][a-zA-Z0-9_]*\(" "$CLASSES_DIR" 2>/dev/null \
      | sed -E "s/.*${prefix_re}([a-zA-Z_][a-zA-Z0-9_]*)\(/\1/" \
      | sort -u
  )
  if [[ ${#methods[@]} -eq 0 ]]; then
    dim "  (검사할 메서드 호출 없음)"
    continue
  fi

  for method in "${methods[@]}"; do
    found=0
    for iface in "${interfaces[@]}"; do
      # `func <method>(` 형태를 각 인터페이스에서 확인
      if grep -qE "func $method[[:space:]]*\(" "$iface"; then
        found=1
        break
      fi
    done
    if [[ $found -eq 1 ]]; then
      green "  ✓ $method"
    else
      red "  ✗ $method  — 번들된 $framework.xcframework 에 없음"
      fail=1
    fi
  done
done

echo
if [[ $fail -ne 0 ]]; then
  red "실패: 소스가 호출하는 심볼이 번들된 프레임워크에 누락되어 있습니다."
  red "릴리스하면 컨슈머에서 'has no member' 컴파일 에러가 발생합니다."
  red "→ TJJupiterSDK/Frameworks/ 의 xcframework 를 올바른 버전으로 갱신하세요."
  exit 1
fi
green "통과: 소스가 호출하는 모든 vendored 심볼이 번들된 프레임워크에 존재합니다."
