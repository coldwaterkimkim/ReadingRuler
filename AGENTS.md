# Repository Guidelines

## Project Structure & Module Organization
`ReadingRuler` is a Swift Package for a macOS menu bar utility. The package entry point is [`Package.swift`](/Users/chansukim/Documents/개인/6-1. codex/리딩룰러/Package.swift). App code lives in `Sources/ReadingRuler/` and is split by responsibility: `App/` for launch and app lifecycle, `Managers/` for state and system services, `UI/` for SwiftUI/AppKit screens and controls, and `Utilities/` for shared helpers. Build artifacts are generated in `.build/`, and distributable app output is stored in `dist/`. There is no `Tests/` directory yet.

## Build, Test, and Development Commands
- `swift build`: compile the debug build from Terminal.
- `swift build -c release`: create an optimized release build.
- `swift run ReadingRuler`: launch the app directly for local verification.
- `open Package.swift`: open the package in Xcode and run the `ReadingRuler` scheme on macOS 14+.
- `swift test`: run the test suite once `Tests/ReadingRulerTests/` exists.

## Coding Style & Naming Conventions
Follow standard Swift conventions: 4-space indentation, one type per file, `UpperCamelCase` for types, and `lowerCamelCase` for properties and methods. Keep files grouped by feature and use descriptive names such as `OverlayCoordinator.swift` or `SettingsWindowController.swift`. Prefer small, focused changes over cross-cutting rewrites. No formatter config is checked in, so use Xcode’s default formatting and keep imports minimal.

## Testing Guidelines
Add tests with XCTest under `Tests/ReadingRulerTests/`. Mirror source areas where possible, for example `AppStateTests.swift` for `Managers/AppState.swift`. Prioritize state transitions, shortcut handling, and overlay geometry logic. For UI-related changes, also verify behavior manually by running the app and checking Accessibility permission flows.

## Commit & Pull Request Guidelines
This repository currently has no commit history, so no existing convention can be inferred. Use short imperative commit messages such as `Add spotlight size reset`. Keep pull requests focused, describe user-visible behavior, list manual test steps, and include screenshots or short recordings for settings or overlay changes. If a change affects permissions, mention the Accessibility impact clearly.

## Security & Configuration Tips
Keep the app local-first: avoid adding network calls, analytics, screen capture, or text extraction without explicit approval. Target macOS 14 or later, and document any new entitlement or permission requirement in `README.md`.

# AGENTS.md

## 프로젝트 목적
- 이 저장소는 현재 운영/개발 중인 실제 프로젝트다.
- 목표는 빠른 기능 추가보다, 망가뜨리지 않는 수정과 검증 가능한 변경이다.

## 작업 규칙
- 수정 전에 관련 파일 후보 3~5개와 이유를 먼저 적어.
- 계획은 5줄 이내로 먼저 적어.
- 바로 큰 리팩터링 하지 마.
- 수정 후에는 변경 파일, 실행한 명령, 결과, 남은 리스크를 요약해.

## 디렉토리 설명
- 여기에 실제 구조를 프로젝트에 맞게 적어
- 예: src, app, components, pages, public, api, server 등

## 실행/검증 명령
- dev: `swift run ReadingRuler` 또는 `open Package.swift` 후 Xcode에서 `ReadingRuler` 스킴 실행
- build: `swift build`, 배포용 확인은 `swift build -c release`
- lint: 현재 전용 lint 도구 없음 (`.swiftlint.yml`, `swiftformat` 설정 없음)
- test: 현재 자동 테스트 없음 (`Tests/` 디렉토리와 `*Tests.swift` 파일 없음)
- e2e: 공식 e2e 자동화 없음, `swift run ReadingRuler` 또는 Xcode 실행 후 메뉴바 아이콘, 접근성 권한, 전역 단축키, 오버레이 동작 수동 확인

## 금지
- 요청 없이 대규모 폴더 이동 금지
- 요청 없이 패키지 대량 교체 금지
- 요청 없이 env/config 변경 금지

## 완료 정의
- 기능이 실제로 동작해야 함
- 가능하면 build/lint/test 중 가능한 검증을 수행
- 남은 리스크를 명시

## 리뷰 규칙
- 리뷰 시 code_review.md를 따른다.
