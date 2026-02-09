# Conti - 시스템 설계 문서

> 예배 콘티 작성 및 찬양 데이터베이스 협업 플랫폼

## 목차

1. [서비스 개요](#서비스-개요)
2. [기술 스택](#기술-스택)
3. [ERD / 데이터베이스 스키마](#erd--데이터베이스-스키마)
4. [REST API 설계](#rest-api-설계)
5. [시스템 아키텍처](#시스템-아키텍처)
6. [인증/권한 설계](#인증권한-설계)

---

## 서비스 개요

| 항목 | 내용 |
|------|------|
| **서비스명** | Conti (가칭) |
| **최종 비전** | 대한민국 모든 예배자의 커뮤니티 플랫폼 |
| **MVP 목표** | 찬양팀을 위한 콘티 작성 & 찬양 데이터베이스 협업 도구 |
| **수익 모델** | 완전 무료 (기부/후원 기반) |

### 타겟 사용자

- 찬양팀 멤버 (보컬, 악기 연주자)
- 찬양 인도자/리더
- 목회자/예배 기획자

### MVP 핵심 기능

1. 소셜 로그인 (카카오, 구글)
2. 팀 생성 및 멤버 초대 (링크 공유)
3. 찬양 데이터베이스 (곡 정보, 태그, 사용 이력)
4. 콘티(셋리스트) 작성 및 팀 내 공유
5. 오프라인 지원

---

## 기술 스택

| 구분 | 기술 |
|------|------|
| **프론트엔드** | React Native 또는 Flutter |
| **백엔드** | Spring Boot (Java) |
| **ORM** | Spring Data JPA + QueryDSL |
| **데이터베이스** | MySQL |
| **인프라** | AWS (EC2 + RDS + S3) |
| **인증** | OAuth2 (카카오, 구글) + JWT |

---

## ERD / 데이터베이스 스키마

### 엔티티 관계도

```
User (1) ←→ (N) TeamMember (N) ←→ (1) Team
                                      │
                                      ├── (1) Team ←→ (N) Song
                                      │                   │
                                      │                   ├── (1) Song ←→ (N) SongTag
                                      │                   ├── (1) Song ←→ (N) SongFile
                                      │                   └── (1) Song ←→ (N) SongUsage
                                      │
                                      └── (1) Team ←→ (N) Setlist
                                                          │
                                                          └── (1) Setlist ←→ (N) SetlistItem
```

### 테이블 스키마

> **참고**: FK 제약조건은 DB 레벨에서 사용하지 않고 JPA 레벨에서만 관리

#### 1. users (사용자)

```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    profile_image VARCHAR(500),
    provider VARCHAR(20) NOT NULL,          -- KAKAO, GOOGLE, APPLE
    provider_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_provider (provider, provider_id)
);
```

#### 2. teams (팀)

```sql
CREATE TABLE teams (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    invite_code VARCHAR(20) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### 3. team_members (팀 멤버)

```sql
CREATE TABLE team_members (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    team_id BIGINT NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'VIEWER',  -- ADMIN, VIEWER, GUEST
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uk_user_team (user_id, team_id),
    INDEX idx_user_id (user_id),
    INDEX idx_team_id (team_id)
);
```

#### 4. songs (찬양)

```sql
CREATE TABLE songs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    team_id BIGINT NOT NULL,
    title VARCHAR(200) NOT NULL,
    artist VARCHAR(100),
    original_key VARCHAR(10),
    bpm INT,
    memo TEXT,
    youtube_url VARCHAR(500),
    music_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_team_id (team_id),
    INDEX idx_team_title (team_id, title)
);
```

#### 5. song_tags (찬양 태그)

```sql
CREATE TABLE song_tags (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    song_id BIGINT NOT NULL,
    tag VARCHAR(50) NOT NULL,               -- 경배, 감사, 사랑, 회개, 선포 등

    INDEX idx_song_id (song_id),
    INDEX idx_tag (tag)
);
```

#### 6. song_files (악보 파일)

```sql
CREATE TABLE song_files (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    song_id BIGINT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    file_type VARCHAR(20),                  -- PDF, IMAGE
    file_size BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_song_id (song_id)
);
```

#### 7. song_usages (곡 사용 이력)

```sql
CREATE TABLE song_usages (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    song_id BIGINT NOT NULL,
    setlist_id BIGINT NOT NULL,
    used_key VARCHAR(10),
    leader_id BIGINT,
    used_at DATE NOT NULL,

    INDEX idx_song_id (song_id),
    INDEX idx_setlist_id (setlist_id),
    INDEX idx_song_usage (song_id, used_at),
    INDEX idx_leader_usage (leader_id, used_at)
);
```

#### 8. setlists (콘티)

```sql
CREATE TABLE setlists (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    team_id BIGINT NOT NULL,
    creator_id BIGINT NOT NULL,
    title VARCHAR(200),
    worship_date DATE NOT NULL,
    worship_type VARCHAR(50),               -- 주일1부, 주일2부, 수요예배 등
    leader_id BIGINT,
    memo TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_team_id (team_id),
    INDEX idx_team_date (team_id, worship_date),
    INDEX idx_creator_id (creator_id),
    INDEX idx_leader_id (leader_id)
);
```

#### 9. setlist_items (콘티 아이템)

```sql
CREATE TABLE setlist_items (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    setlist_id BIGINT NOT NULL,
    song_id BIGINT NOT NULL,
    order_index INT NOT NULL,
    song_key VARCHAR(10),
    memo TEXT,

    INDEX idx_setlist_id (setlist_id),
    INDEX idx_song_id (song_id),
    INDEX idx_setlist_order (setlist_id, order_index)
);
```

---

## REST API 설계

### Base URL

```
/api/v1
```

### Auth API

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/auth/login/{provider}` | 소셜 로그인 (kakao, google) |
| POST | `/auth/refresh` | 토큰 갱신 |
| POST | `/auth/logout` | 로그아웃 |

### User API

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/users/me` | 내 정보 조회 |
| PATCH | `/users/me` | 내 정보 수정 |
| GET | `/users/me/teams` | 내가 속한 팀 목록 |

### Team API

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/teams` | 팀 생성 |
| GET | `/teams/{teamId}` | 팀 정보 조회 |
| PATCH | `/teams/{teamId}` | 팀 정보 수정 |
| DELETE | `/teams/{teamId}` | 팀 삭제 |
| GET | `/teams/{teamId}/members` | 팀원 목록 조회 |
| POST | `/teams/{teamId}/members` | 팀원 추가 |
| PATCH | `/teams/{teamId}/members/{memberId}` | 역할 변경 |
| DELETE | `/teams/{teamId}/members/{memberId}` | 팀원 제거 |
| POST | `/teams/{teamId}/invite` | 초대 링크 생성/갱신 |
| POST | `/teams/join/{inviteCode}` | 초대 링크로 가입 |

### Song API

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/teams/{teamId}/songs` | 찬양 목록 (필터/검색) |
| POST | `/teams/{teamId}/songs` | 찬양 추가 |
| GET | `/teams/{teamId}/songs/{songId}` | 찬양 상세 |
| PATCH | `/teams/{teamId}/songs/{songId}` | 찬양 수정 |
| DELETE | `/teams/{teamId}/songs/{songId}` | 찬양 삭제 |
| GET | `/teams/{teamId}/songs/{songId}/usages` | 사용 이력 조회 |
| POST | `/teams/{teamId}/songs/{songId}/files` | 악보 파일 업로드 |
| DELETE | `/teams/{teamId}/songs/{songId}/files/{fileId}` | 악보 삭제 |
| GET | `/teams/{teamId}/tags` | 팀 태그 목록 |

#### Song 검색/필터 파라미터

```
GET /api/v1/teams/{teamId}/songs

Query Parameters:
- keyword: 제목/아티스트 검색
- tags: 태그 필터 (쉼표 구분, OR 조건)
- key: 키 필터
- unusedWeeks: 최근 N주 미사용 필터
- leaderId: 인도자별 필터
- page: 페이지 번호 (0부터)
- size: 페이지 크기
```

### Setlist API

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/teams/{teamId}/setlists` | 콘티 목록 (날짜 필터) |
| POST | `/teams/{teamId}/setlists` | 콘티 생성 |
| GET | `/teams/{teamId}/setlists/{setlistId}` | 콘티 상세 |
| PATCH | `/teams/{teamId}/setlists/{setlistId}` | 콘티 수정 |
| DELETE | `/teams/{teamId}/setlists/{setlistId}` | 콘티 삭제 |
| POST | `/teams/{teamId}/setlists/{setlistId}/items` | 곡 추가 |
| PATCH | `/teams/{teamId}/setlists/{setlistId}/items/{itemId}` | 곡 수정 |
| DELETE | `/teams/{teamId}/setlists/{setlistId}/items/{itemId}` | 곡 제거 |
| PATCH | `/teams/{teamId}/setlists/{setlistId}/items/reorder` | 순서 일괄 변경 |

#### Setlist 검색/필터 파라미터

```
GET /api/v1/teams/{teamId}/setlists

Query Parameters:
- fromDate: 시작 날짜
- toDate: 종료 날짜
- worshipType: 예배 유형 필터
- page: 페이지 번호
- size: 페이지 크기
```

---

## 시스템 아키텍처

### 전체 시스템 구조

```
┌─────────────────────────────────────────────────────────────────────┐
│                            Client                                    │
├──────────────────────────────┬──────────────────────────────────────┤
│      Mobile App              │              Web App                  │
│   (React Native/Flutter)     │        (React/Next.js)               │
└──────────────────────────────┴──────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          AWS Cloud                                   │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐                           ┌─────────────────┐  │
│  │   CloudFront    │                           │      S3         │  │
│  │   (CDN/정적)    │                           │  (파일 저장)    │  │
│  └─────────────────┘                           └─────────────────┘  │
│                                                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    Application Server                          │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │                 Spring Boot Application                  │  │  │
│  │  ├─────────────────────────────────────────────────────────┤  │  │
│  │  │  Controller → Service → Repository (JPA + QueryDSL)     │  │  │
│  │  ├─────────────────────────────────────────────────────────┤  │  │
│  │  │  Security (JWT + OAuth2)  │  Exception Handler          │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  │                         EC2 / ECS                              │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                  │                                   │
│                                  ▼                                   │
│  ┌─────────────────┐    ┌─────────────────┐                         │
│  │      RDS        │    │  ElastiCache    │                         │
│  │    (MySQL)      │    │ (Redis) - 선택  │                         │
│  └─────────────────┘    └─────────────────┘                         │
└─────────────────────────────────────────────────────────────────────┘
```

### Spring Boot 패키지 구조

```
src/main/java/com/conti/
├── ContiApplication.java
│
├── global/                      # 공통 설정
│   ├── config/
│   │   ├── SecurityConfig.java
│   │   ├── JpaConfig.java
│   │   ├── QueryDslConfig.java
│   │   └── WebConfig.java
│   ├── auth/
│   │   ├── jwt/
│   │   │   ├── JwtTokenProvider.java
│   │   │   └── JwtAuthenticationFilter.java
│   │   └── oauth2/
│   │       ├── OAuth2UserService.java
│   │       └── OAuth2SuccessHandler.java
│   ├── error/
│   │   ├── ErrorCode.java
│   │   ├── BusinessException.java
│   │   └── GlobalExceptionHandler.java
│   └── common/
│       ├── BaseEntity.java
│       └── ApiResponse.java
│
├── domain/                      # 도메인별 패키지
│   ├── user/
│   │   ├── entity/
│   │   ├── repository/
│   │   ├── service/
│   │   ├── controller/
│   │   └── dto/
│   ├── team/
│   │   ├── entity/
│   │   ├── repository/
│   │   ├── service/
│   │   ├── controller/
│   │   └── dto/
│   ├── song/
│   │   ├── entity/
│   │   ├── repository/
│   │   ├── service/
│   │   ├── controller/
│   │   └── dto/
│   └── setlist/
│       ├── entity/
│       ├── repository/
│       ├── service/
│       ├── controller/
│       └── dto/
│
└── infra/                       # 외부 인프라 연동
    ├── s3/
    │   └── S3FileService.java
    └── oauth/
        ├── KakaoOAuth2Client.java
        └── GoogleOAuth2Client.java
```

### AWS 인프라 구성 (MVP)

| 서비스 | 용도 | 예상 비용 (월) |
|--------|------|---------------|
| EC2 (t3.small) | Spring Boot 서버 | ~$15 |
| RDS (db.t3.micro) | MySQL | ~$15 |
| S3 | 악보 파일 저장 | ~$1 |
| CloudFront | 정적 파일 CDN | ~$1 |
| **총 예상** | | **~$32/월** |

---

## 인증/권한 설계

### JWT 토큰 구조

```
Access Token (만료: 1시간)
{
  "sub": "123",              // userId
  "email": "user@test.com",
  "iat": 1704067200,
  "exp": 1704070800
}

Refresh Token (만료: 14일)
{
  "sub": "123",
  "type": "refresh",
  "iat": 1704067200,
  "exp": 1705276800
}
```

### 소셜 로그인 흐름

```
1. Client → 카카오/구글 로그인 → Authorization Code 획득

2. Client → POST /api/v1/auth/login/kakao
            Body: { "code": "authorization_code" }

3. Server → 카카오 API로 Access Token 요청
         → 카카오 사용자 정보 조회
         → User 테이블 조회/생성 (신규면 회원가입)
         → JWT (Access + Refresh) 발급

4. Server → Client
            { "accessToken": "...", "refreshToken": "..." }
```

### 팀 역할 및 권한

| 역할 | 설명 |
|------|------|
| **ADMIN** | 팀 관리자 (복수 가능) |
| **VIEWER** | 일반 팀원 |
| **GUEST** | 열람 권한자 (팀 외부인) |

### 권한 매트릭스

| 기능 | ADMIN | VIEWER | GUEST |
|------|:-----:|:------:|:-----:|
| 팀 정보 수정 | ✅ | ❌ | ❌ |
| 팀원 초대/제거 | ✅ | ❌ | ❌ |
| 역할 변경 | ✅ | ❌ | ❌ |
| 찬양 추가/수정/삭제 | ✅ | ❌ | ❌ |
| 콘티 생성/수정/삭제 | ✅ | ❌ | ❌ |
| 찬양 목록 조회 | ✅ | ✅ | ✅ |
| 콘티 조회 | ✅ | ✅ | ✅ |
| 악보 다운로드 | ✅ | ✅ | ✅ |

### 권한 검증 구현

```java
// 커스텀 어노테이션
@TeamAuth(roles = {TeamRole.ADMIN})
@PostMapping("/teams/{teamId}/songs")
public ApiResponse<SongResponse> createSong(...) { }

@TeamAuth(roles = {TeamRole.ADMIN, TeamRole.VIEWER, TeamRole.GUEST})
@GetMapping("/teams/{teamId}/setlists")
public ApiResponse<List<SetlistResponse>> getSetlists(...) { }
```

---

## 다음 단계

1. `/sc:workflow` - 개발 워크플로우/스프린트 계획 수립
2. `/sc:implement` - 실제 구현 시작

---

*문서 작성일: 2026-02-05*
