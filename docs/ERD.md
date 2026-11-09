# ISM Museum — ERD

```mermaid
erDiagram
    AUTH_USERS ||--o| PROFILES : owns
    AUTH_USERS ||--o| MUSEUM_ADMINS : authorized
    AUTH_USERS ||--o{ EXHIBITS : creates
    EVENTS ||--o{ EVENT_PHOTOS : contains
    AUTH_USERS { uuid id PK }
    PROFILES { uuid id PK, text display_name, text avatar_url, text bio }
    MUSEUM_ADMINS { uuid user_id PK }
    EXHIBITS { uuid id PK, uuid creator_id FK, text title, text description, text image_url, text category, text_array technology_stack, int year_created, text demo_url, text github_url, text status }
    TEACHERS { text id PK, text name, text position, text_array courses, text bio, text photo_url }
    EVENTS { text id PK, text title, date event_date, text description, text cover_image_url }
    EVENT_PHOTOS { uuid id PK, text event_id FK, text image_url, text caption }
    EXHIBITION_CATEGORIES { uuid id PK, text name, text description }
    MILESTONES { uuid id PK, int year, text title, text description }
```

- `PRIMARY KEY` мөр бүрийг цор ганц танина.
- `FOREIGN KEY` нь өөр хүснэгтийн өгөгдөлд холбогдоно: `exhibits.creator_id` → `auth.users.id`, `event_photos.event_id` → `events.id`.
- `museum_admins` нь Auth-аас бие даасан trusted permission хүснэгт. Хэрэглэгч өөрөө админ эрхийг өөрчлөх боломжгүй.
- Бүх `public` хүснэгтүүдэд RLS enabled.
