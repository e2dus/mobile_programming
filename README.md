# 📸 Flutter Instagram Clone with Gemini AI & Supabase

[![Flutter](https://img.shields.io/badge/Flutter-3.8+-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Riverpod](https://img.shields.io/badge/State%20Management-Riverpod%203.0-00B4AB)]()
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com/)
[![Gemini AI](https://img.shields.io/badge/AI-Google%20Gemini-4285F4?logo=google&logoColor=white)](https://ai.google.dev/)

> **모바일 프로그래밍 개인 프로젝트 (Mobile Programming Individual Project)**  
> **Flutter + Riverpod + Supabase BaaS + Google Gemini AI** 기반의 크로스플랫폼 소셜 미디어(Instagram 클론) 애플리케이션입니다.

---

## ✨ 핵심 기능 (Key Features)

| 카테고리 | 상세 기능 |
|---|---|
| **🏠 피드 & 멀티미디어 캐러셀** | 다중 이미지 캐러셀, 피드 스크롤 가시성(`VisibilityDetector`) 기반 **비디오 자동 재생(Auto-play)** 및 썸네일 프리로딩 최적화 |
| **💬 Google Gemini AI 다이렉트 메시지(DM)** | `google_generative_ai` SDK 연동 실시간 AI 페르소나 챗봇과의 1:1 DM 대화, 읽음 처리, 미디어 공유 |
| **➕ 게시물 작성 & 갤러리 연동** | `photo_manager` 및 `image_picker`를 활용한 기기 갤러리 커스텀 피커, 사진/동영상 업로드, 캡션 작성 |
| **📖 스토리 & 릴스(Reels)** | 팔로워 스토리 뷰어 및 추천 릴스(Suggested Reels) 비디오 스트리밍 UI |
| **👤 프로필 관리 & 소셜 그래프** | 이름/소개글(Bio)/아바타 실시간 편집, 팔로우/언팔로우 상태 동기화, 게시물 그리드-피드 연동 네비게이션 |
| **🔔 인터랙션 & 실시간 알림** | 게시물 좋아요 애니메이션, 바텀시트 댓글 작성/조회, 활동 알림 피드 |

---

## 🛠️ 기술 스택 (Tech Stack)

- **Framework & Language**: Flutter (`>=3.8.1 <4.0.0`), Dart
- **State Management**: `flutter_riverpod` (`^3.0.3`) — 도메인별 Notifier 분리 (`posts`, `stories`, `chats`, `messages`, `comments`, `users`, `video_player`, `notifications`)
- **Backend & Storage**: `supabase_flutter` (`^2.10.3`) — 인증, PostgreSQL 데이터베이스, 미디어 스토리지 연동
- **AI Integration**: `google_generative_ai` (`^0.4.7`) — Gemini 기반 실시간 DM 대화 생성
- **Media & UI**:
  - `video_player`, `video_thumbnail`, `visibility_detector` (피드 내 인라인 비디오 자동 재생/일시정지 제어)
  - `photo_manager`, `photo_manager_image_provider`, `image_picker` (네이티브 갤러리 에셋 그리드 로딩)
  - `cached_network_image`, `flutter_screenutil`, `flutter_svg` (반응형 UI 및 이미지 캐싱)

---

## 📁 프로젝트 구조 (Project Structure)

```text
lib/
├── main.dart                          # 앱 진입점, Supabase 초기화 및 ProviderScope 설정
├── api_keys.dart                      # 환경변수(--dart-define) 기반 API 키 설정
├── components/                        # 공통 UI 컴포넌트 (like_button, search_bar, story_icon)
├── models/                            # 데이터 모델 (post, story, user, chat, message, comment, notification)
├── pages/                             # 주요 화면 (instagram_feed, create_post, direct_message, profile, gallery_picker 등)
├── providers/                         # Riverpod 상태 관리 Notifier 모음
│   ├── app_providers.dart
│   ├── posts_notifier.dart
│   ├── stories_notifier.dart
│   ├── chats_notifier.dart
│   ├── message_notifier.dart
│   ├── comments_notifier.dart
│   ├── users_notifier.dart
│   └── video_player_notifier.dart
├── services/                          # 게시물 업로드 및 외부 서비스 연동 (upload_post_service.dart)
├── sheets/                            # 공유하기 및 액션 바텀 시트
├── states/                            # 비디오 플레이어 등 불변 상태 클래스
├── utils/                             # 상대 시간 포맷팅(time_ago_en), 네비게이션 헬퍼
└── widgets/                           # 도메인별 커스텀 위젯 (post/, chat/, dm/, story/, reels/, edit_profile/)
```

---

## 🚀 실행 방법 (Getting Started)

### 1. 저장소 클론 및 패키지 설치

```bash
git clone https://github.com/e2dus/mobile_programming.git
cd mobile_programming
flutter pub get
```

### 2. API 키 설정 및 실행

`--dart-define` 옵션을 통해 Supabase 및 Gemini API 키를 주입하거나, 로컬 개발 시 `lib/api_keys.dart`에 키를 입력하여 실행합니다:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key \
  --dart-define=GEMINI_API_KEY=your_gemini_api_key
```

---

## 👤 Author

- **정의연 (Ui-Yeon Jeong)** — 중앙대학교 AI학과 (`e2dus`)
