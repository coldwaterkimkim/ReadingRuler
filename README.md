# ReadingRuler

ReadingRuler is a macOS menu bar utility that adds a system-wide reading ruler overlay that follows the cursor.

리딩룰러는 커서를 따라다니는 시스템 전체용 읽기 눈금자 오버레이를 제공하는 macOS 메뉴바 앱이야.

The downloadable app bundle is currently packaged with the display name `울트라돌멩의 밑줄긋기`.

현재 배포되는 앱 번들의 표시 이름은 `울트라돌멩의 밑줄긋기`야.

## Download / 다운로드

Download the latest packaged app from GitHub Releases:

최신 패키지 앱은 GitHub Releases에서 받을 수 있어:

- <https://github.com/coldwaterkimkim/ReadingRuler/releases/latest>

## Features / 기능

- Hold-to-show ruler (global shortcut)
- 누르고 있는 동안만 표시되는 눈금자 모드 (전역 단축키)
- Sticky toggle mode (global shortcut)
- 켜짐 상태를 유지하는 고정 모드 토글 (전역 단축키)
- 3 modes: Bar, Highlight, Spotlight
- 3가지 모드: 바, 하이라이트, 스포트라이트
- Draggable quick-adjust handle for width/height, with `Option` drag to adjust offset
- 드래그 핸들로 가로/세로 크기를 빠르게 조절하고, `Option` 드래그로 오프셋을 조절
- Settings persistence via `UserDefaults`
- `UserDefaults` 기반 설정 저장
- No screen recording, text capture, analytics, or network calls
- 화면 녹화, 텍스트 수집, 분석, 네트워크 호출 없음
- Lightweight runtime path: single overlay window and cursor tracking only while ruler is visible
- 눈금자가 보일 때만 커서를 추적하는 가벼운 동작 구조

## Run From Source / 소스에서 실행

1. Open `Package.swift` in Xcode (Xcode treats this as a native Swift project).
2. Choose the `ReadingRuler` scheme.
3. Run on macOS 14+.

1. Xcode에서 `Package.swift`를 열어.
2. `ReadingRuler` 스킴을 선택해.
3. macOS 14 이상에서 실행해.

You can also build from terminal:

터미널에서는 이렇게 빌드하면 돼:

```bash
swift build
```

For a release-style terminal build:

배포용에 가까운 빌드는 이렇게 하면 돼:

```bash
swift build -c release
```

## Permissions / 권한

ReadingRuler uses global shortcuts and global cursor tracking for overlay rendering.

리딩룰러는 오버레이 표시를 위해 전역 단축키와 전역 커서 추적을 사용해.

If shortcuts do not fire reliably, grant Accessibility permission:

단축키가 잘 먹지 않으면 손쉬운 사용 권한을 허용해줘:

1. Open **System Settings** → **Privacy & Security** → **Accessibility**.
2. Enable access for `ReadingRuler` or `울트라돌멩의 밑줄긋기`.

1. **시스템 설정** → **개인정보 보호 및 보안** → **손쉬운 사용**으로 이동해.
2. `ReadingRuler` 또는 `울트라돌멩의 밑줄긋기` 항목을 켜줘.

You can open this page from the app Settings screen via **Open Accessibility Settings**.

앱 설정 화면의 **Open Accessibility Settings** 버튼으로도 바로 열 수 있어.

## Default Shortcuts / 기본 단축키

- Hold-to-show: `Option + Space`
- 누르고 있는 동안 표시: `Option + Space`
- Toggle sticky ruler: `Control + Command + R`
- 고정 모드 토글: `Control + Command + R`

All shortcuts are configurable in Settings.

모든 단축키는 Settings에서 바꿀 수 있어.

## Hold-to-Show Usage / 눌러서 보기 사용법

- Press and hold the hold shortcut to show the ruler instantly.
- 단축키를 누르고 있는 동안 눈금자가 바로 나타나.
- While held, the overlay follows the cursor.
- 누르고 있는 동안 오버레이가 커서를 따라다녀.
- Release the shortcut to hide instantly.
- 단축키에서 손을 떼면 바로 사라져.

## Privacy / 개인정보

ReadingRuler runs locally only:

리딩룰러는 로컬에서만 동작해:

- No network requests
- 네트워크 요청 없음
- No text extraction
- 텍스트 추출 없음
- No screenshots or screen recording
- 스크린샷 생성이나 화면 녹화 없음
