# 프로젝트: dongdong9

## 설명

이 앱은 부부의 현명한 소비와 절약을 돕기 위해 만들어졌습니다. 공동의 예산을 설정하고, 각 카테고리별로 예산을 할당한 뒤, 지출이 발생할 때마다 기록하여 예산 관리를 용이하게 하는 것을 목표로 합니다.

## 프로젝트 구조

이 프로젝트는 다음과 같이 구성된 표준 SwiftUI 애플리케이션입니다:

- `dongdong9/`: 메인 애플리케이션 소스 코드.
    - `dongdong9App.swift`: `App` 프로토콜을 따르는 애플리케이션의 메인 진입점입니다.
    - `ContentView.swift`: 애플리케이션의 메인 뷰입니다.
    - `Assets.xcassets`: 앱 아이콘 및 강조 색상과 같은 앱의 모든 시각적 자산을 포함합니다.
    - `Preview Content/`: SwiftUI 미리보기에 특별히 사용되는 자산입니다.
- `dongdong9.xcodeproj/`: Xcode 프로젝트 파일입니다. 프로젝트에 대한 설정 및 구성을 포함합니다.
- `dongdong9Tests/`: 단위 테스트를 위한 타겟입니다.
    - `dongdong9Tests.swift`: 예제 단위 테스트 파일입니다.
- `dongdong9UITests/`: UI 테스트를 위한 타겟입니다.
    - `dongdong9UITests.swift`: 예제 UI 테스트 파일입니다.
- `functions/`: Firebase Functions 관련 코드.
    - `src/index.ts`: Firebase Functions의 메인 소스 코드 파일입니다.

## 디자인 패턴

이 프로젝트는 MVVM (Model-View-ViewModel) 아키텍처 패턴을 따릅니다.

## 기술 스택

- **서버 통신**: Firebase Functions
- **데이터베이스**: Cloud Firestore

## x Project Context
- Repository: github.com/wangkobong/dongdong9