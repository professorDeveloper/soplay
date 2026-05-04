# Shorts UI Redesign — Design Spec

## Goal

Completely redesign the Shorts feature UI to match YouTube Shorts / Instagram Reels quality. Update API integration to use the new cursor-based pagination. Ensure all UI elements map exactly to the API response fields.

---

## API Contract

### Feed Endpoint (changed)

```
GET /api/shorts/feed?limit=10
GET /api/shorts/feed?limit=10&cursor=6830a1f2e4b09c001234abcd
GET /api/shorts/feed?q=avengers&limit=10&cursor=...
```

Response:
```json
{
  "items": [...],
  "nextCursor": "6830a1f2e4b09c001234abcd",
  "hasMore": true
}
```

- First request: no `cursor` param
- Next page: send previous response's `nextCursor` as `cursor`
- Stop when: `hasMore: false` OR `nextCursor: null`
- Search: `q` param searches `title`, `contentTitle`, `tags`

### Item Response (unchanged)

```json
{
  "_id": "...",
  "title": "Iron Man sahna",
  "videoUrl": "https://cdn.soplay.uz/shorts/videos/abc.mp4",
  "thumbnailUrl": "https://cdn.soplay.uz/shorts/thumbnails/abc.jpg",
  "provider": "asilmedia",
  "contentTitle": "Iron Man 3",
  "contentThumbnail": "https://...",
  "views": 1240,
  "likeCount": 87,
  "likedByMe": false,
  "tags": ["marvel", "action"],
  "createdAt": "2025-05-01T10:00:00.000Z"
}
```

**Fields NOT shown in sample but may still exist**: `contentUrl` — needed for detail navigation via `DetailArgs`. Keep in entity.

**Fields to remove from entity** (not in API): `author`, `authorAvatar`, `description`.

### Other Endpoints (unchanged)

| Endpoint | Change |
|----------|--------|
| `GET /api/shorts/:id` | No change |
| `POST /api/shorts/:id/view` | No change |
| `POST /api/shorts/:id/like` | No change |

---

## Data Layer Changes

### ShortEntity — update fields to match API

Remove: `author`, `authorAvatar`, `description`.

Keep/rename:
- `id` <- `_id`
- `title` <- `title`
- `videoUrl` <- `videoUrl`
- `thumbnail` <- `thumbnailUrl`
- `provider` <- `provider`
- `contentTitle` <- `contentTitle`
- `contentThumbnail` <- `contentThumbnail`
- `viewCount` <- `views`
- `likeCount` <- `likeCount`
- `likedByMe` <- `likedByMe`
- `tags` <- `tags`
- `createdAt` <- `createdAt` (new, String)

### ShortModel.fromJson — simplify

Remove all the fallback field name guessing (e.g., `json['video'] ?? json['mediaUrl']`). Map directly to the known API fields:
- `id` = `json['_id']`
- `title` = `json['title']`
- `videoUrl` = `json['videoUrl']`
- `thumbnail` = `json['thumbnailUrl']`
- `provider` = `json['provider']`
- `contentTitle` = `json['contentTitle']`
- `contentThumbnail` = `json['contentThumbnail']`
- `viewCount` = `json['views']`
- `likeCount` = `json['likeCount']`
- `likedByMe` = `json['likedByMe']`
- `tags` = `json['tags']`
- `createdAt` = `json['createdAt']`

### DataSource — add `q` param

`getShortsFeed({String? cursor, String? query, int limit})` — pass `q` query param when provided.

### GetShortsUseCase — add `query` param

`call({String? cursor, String? query, int limit})` forwards to repository.

---

## UI Layout — Per Reel Item

Full-screen vertical PageView. Each item is a Stack:

```
+--------------------------------------------------+
|  [safe area]                                      |
|  "Shorts"  (transparent AppBar, left-aligned)     |
|                                                   |
|                                                   |
|              [VIDEO / THUMBNAIL]                  |
|                                                   |
|          [buffering: blur thumb + spinner]         |
|                                                   |
|      [tap: play/pause icon, fade out]             |
|      [long press: "2x" pill badge]                |
|      [double tap: heart burst, like only]         |
|                                                   |
|                                   [SIDE RAIL]     |
|                                    Like 24px      |
|                                     87            |
|                                                   |
|                                    Views 22px     |
|                                     1.2K          |
|                                                   |
|                                    Share 24px     |
|                                                   |
|  provider ("asilmedia")                           |
|  title ("Iron Man sahna") max 2 lines             |
|  #marvel  #action  (tags, max 3)                  |
|                                                   |
|  [==== PILL BUTTON (center, wide) ============]   |
|  [ [thumb] Iron Man 3        Watch Full Movie > ] |
|                                                   |
|  [============ thin progress bar ==============]  |
+--------------------------------------------------+
```

---

## Component Details

### 1. Transparent AppBar

- `Positioned` at top, inside safe area
- Left: "Shorts" text (localized), 18px, bold, white, shadow for readability
- Top scrim gradient behind it (black 0.45 -> transparent, 100px height)
- Always visible during scroll

### 2. Video Background

- `VideoPlayer` centered with aspect ratio
- Before init: `thumbnailUrl` shown with `ImageFilter.blur(sigmaX: 10, sigmaY: 10)` + center spinner
- Thumbnail missing: black background + spinner
- Error: dark overlay + broken image icon + "Video unavailable"

### 3. Tap — Play/Pause

- Single tap toggles play/pause
- Center icon appears: play or pause (48px, white, circular semi-transparent bg)
- Animation: scale up from 0.5 to 1.0 + after 1.5s fade out
- No multi-step controls — one tap does it

### 4. Double Tap — Like Only

- Double tap anywhere = add like (POST /api/shorts/:id/like)
- Heart burst animation at tap position (Instagram-style)
- If already liked: only show heart burst effect, don't send API call
- Does NOT unlike — unlike is only via side rail toggle
- Haptic feedback (medium impact)

### 5. Long Press — 2x Speed

- Long press and hold = set playback speed to 2.0x
- Show "2x" pill badge at top-center (rounded, semi-transparent black bg, white text)
- Badge appears with scale animation
- Release = back to 1.0x, badge fades out
- Haptic feedback on activate (light impact)

### 6. Side Rail (right side)

Positioned right: 12, bottom: 130. Column with 18px spacing:

**Like button:**
- Icon: `favorite_rounded` (liked) / `favorite_border_rounded` (not liked), 24px
- Color: red (liked) / white (not liked)
- Count: `likeCount`, 11px, white, bold — formatted (1.2K, 87)
- Tap = toggle like/unlike (optimistic update)
- Loading state: small spinner replaces icon

**Views:**
- Icon: `remove_red_eye_outlined`, 22px, white
- Count: `views`, 11px, white — formatted
- No tap action, display only

**Share:**
- Icon: `share_rounded` (iOS) / `share_outlined`, 24px, white
- Tap = share short URL via system share sheet

All icons have subtle shadow for readability.

### 7. Bottom Meta

Left-aligned, right padding for side rail (76px).

**Provider name:**
- `provider` text, 12px, bold, white with slight opacity (0.85)
- Skip if empty

**Title:**
- `title`, max 2 lines, 14px, semibold, white
- Text shadow for readability
- Skip if empty

**Tags row:**
- Horizontal row from `tags[]`
- Each tag: "#tag" text, 11px, inside small rounded container (white10 bg, white70 text)
- Max 3 tags shown, horizontal scroll disabled, overflow hidden
- 6px spacing between tags
- Skip if tags empty

**Pill button (Watch Full Movie):**
- Centered, width: screen width - 80px (40px padding each side)
- Height: 42px
- Rounded: 21px
- Background: primary gradient (E53935 -> B71C1C)
- Shadow: red with 0.35 opacity, blur 12
- Layout: Row — [contentThumbnail 28x28 rounded 6px] [8px] [contentTitle, 13px bold, white, ellipsis] [Spacer] ["Watch" 12px white70] [chevron 16px]
- If `contentTitle` is empty: hide entire button
- If `contentThumbnail` is empty: show movie icon placeholder
- Tap = save provider to Hive, push /detail with contentTitle-based args

**Thin progress bar:**
- Always visible, 2.5px height
- White track on white24 background
- Rounded corners
- When tapped (controls visible): expands to full Slider + time labels (mm:ss / mm:ss)
- Slider: white thumb 7px, white active track, white30 inactive
- Time labels: 11px, white70

### 8. Seekbar Behavior

- Thin bar always renders (no setState thrashing — uses `ValueListenableBuilder` or listener optimization)
- Tap on video shows controls: center play/pause + full seekbar + time
- Controls auto-hide after 3s
- While seeking: controls stay visible
- Animations via `AnimationController` — no redundant rebuilds

---

## Pagination & Load More

### Bloc State

`ShortsLoaded` already has: `items`, `nextCursor`, `hasMore`, `loadingMore`, `activeIndex`.

### Flow

1. `ShortsLoad` -> fetch `/shorts/feed?limit=15` (no cursor)
2. Store `nextCursor` and `hasMore` from response
3. `ShortsPageChanged(index)` -> if `index >= items.length - 3` AND `hasMore` AND `!loadingMore` -> dispatch `ShortsLoadMore`
4. `ShortsLoadMore` -> fetch `/shorts/feed?limit=15&cursor=<nextCursor>`
5. Append new items, update `nextCursor`/`hasMore`
6. `hasMore: false` or `nextCursor: null` -> stop

### PageView

- `itemCount` = `items.length + (loadingMore ? 1 : 0)` — last item is a loading spinner
- When loadingMore: last page shows small centered spinner on black bg

---

## Detail Navigation

`DetailArgs` requires `contentUrl`. The API sample didn't list `contentUrl` but user stated "item format unchanged" — so `contentUrl` is assumed to still be present. The existing `_openDetail` flow (save provider to Hive, push `/detail` with `DetailArgs(contentUrl: ...)`) remains unchanged.

If `contentUrl` turns out to be missing at runtime, the pill button hides itself (same as current behavior: `if (short.contentUrl.trim().isNotEmpty)`).

---

## Files to Modify

### Data layer
1. `lib/features/shorts/domain/entities/short_entity.dart` — remove unused fields, add `createdAt`
2. `lib/features/shorts/data/models/short_model.dart` — simplify fromJson to match exact API
3. `lib/features/shorts/data/datasources/shorts_remote_data_source.dart` — add `query` param
4. `lib/features/shorts/domain/usecases/get_shorts_usecase.dart` — add `query` param
5. `lib/features/shorts/domain/repositories/shorts_repository.dart` — add `query` param
6. `lib/features/shorts/data/repositories/shorts_repository_impl.dart` — forward `query`

### Bloc layer
7. `lib/features/shorts/presentation/bloc/shorts_event.dart` — no change needed (already has cursor-based events)
8. `lib/features/shorts/presentation/bloc/shorts_state.dart` — no change needed
9. `lib/features/shorts/presentation/bloc/shorts_bloc.dart` — already cursor-based, verify correctness

### UI layer
10. `lib/features/shorts/presentation/pages/shorts_page.dart` — add transparent AppBar, load more indicator
11. `lib/features/shorts/presentation/widgets/short_reel_item.dart` — full rewrite: new interactions, layout, side rail
12. `lib/features/shorts/presentation/widgets/shorts_state_views.dart` — minor tweaks if needed

### Shared
13. Check `DetailArgs` to understand how detail navigation should work without `contentUrl`
