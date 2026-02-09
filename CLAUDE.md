# CLAUDE.md

## Project: Conti Flutter
예배팀 콘티(세트리스트) + 찬양 데이터베이스 협업 플랫폼 - Mobile App
Tech: Flutter (Dart 3.10+), Riverpod, GoRouter, Dio

## Commands
```bash
flutter pub get        # 의존성 설치
flutter run            # 앱 실행 (디바이스/에뮬레이터)
flutter build apk      # Android APK 빌드
flutter build ios      # iOS 빌드
flutter test           # 테스트 실행
flutter analyze        # 정적 분석
dart run build_runner build --delete-conflicting-outputs  # 코드 생성 (Riverpod, JSON)
```

## Design Document
`docs/DESIGN.md`를 반드시 읽고 구현할 것 (ERD, API 스펙, 인증 플로우, 아키텍처)

## Backend API
- Base URL: `http://localhost:8080/api/v1` (개발 환경)
- Backend repo: conti-backend

## Package Structure
```
lib/
├── main.dart
├── core/               # 핵심 인프라
│   ├── api/            # API 클라이언트 (Dio), 응답 모델
│   ├── auth/           # 인증 관련 (토큰 관리)
│   ├── constants/      # 앱 상수, 테마
│   └── storage/        # SecureStorage 래퍼
├── models/             # 데이터 모델 (User, Team, Song, Setlist)
├── providers/          # Riverpod 프로바이더
├── routes/             # GoRouter 라우팅
├── screens/            # 화면별 패키지
│   ├── auth/           # 로그인, 스플래시
│   ├── home/           # 홈
│   ├── profile/        # 프로필
│   ├── setlist/        # 콘티 목록/상세/작성
│   ├── song/           # 찬양 목록/상세/작성
│   └── team/           # 팀 생성/상세/가입/멤버
└── widgets/            # 공통 위젯
```

## Coding Conventions
1. 상태관리: Riverpod (flutter_riverpod + riverpod_annotation + riverpod_generator)
2. 라우팅: GoRouter
3. HTTP: Dio (core/api/api_client.dart)
4. 보안 저장소: flutter_secure_storage (JWT 토큰 저장)
5. 코드 생성: build_runner (JSON serialization, Riverpod generator)
6. 모델: @JsonSerializable, fromJson/toJson 패턴
7. 화면 구조: screens/{feature}/ 디렉토리별 구분
8. 네이밍: snake_case (파일명), PascalCase (클래스), camelCase (변수/함수)

## Key Dependencies
- dio: ^5.7.0 (HTTP client)
- flutter_riverpod: ^2.6.1 (상태관리)
- go_router: ^14.8.1 (라우팅)
- flutter_secure_storage: ^9.2.4 (보안 저장소)
- json_annotation + json_serializable (JSON 직렬화)
- cached_network_image: ^3.4.1 (이미지 캐싱)
