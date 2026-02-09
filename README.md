# Conti Flutter

> 예배팀 콘티(세트리스트) + 찬양 데이터베이스 협업 플랫폼 - Mobile App

## 기술 스택

| 구분 | 기술 |
|------|------|
| Framework | Flutter (Dart 3.10+) |
| 상태관리 | Riverpod |
| 라우팅 | GoRouter |
| HTTP | Dio |
| 보안저장소 | flutter_secure_storage |

## 시작하기

### 사전 준비
- Flutter SDK 3.10+
- Android Studio / Xcode (플랫폼별)

### 실행
```bash
flutter pub get
flutter run
```

### 코드 생성
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Backend API
- Backend repo: [conti-backend](https://github.com/yoochangyeon/conti-backend)
- Base URL (개발): http://localhost:8080/api/v1

## 문서
- [시스템 설계 문서](./docs/DESIGN.md)
- [세션 컨텍스트](./docs/SESSION_CONTEXT.md)

## 라이선스
MIT License
