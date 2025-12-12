-- ============================================
-- 05_views.sql
-- 외힙 메타데이터 DB 뷰 정의 스크립트
-- ============================================

USE hiphopdb;

-- 먼저 기존 뷰가 있다면 삭제 (여러 번 실행해도 안전하게)
DROP VIEW IF EXISTS v_track_detail;
DROP VIEW IF EXISTS v_track_with_tags;
DROP VIEW IF EXISTS v_artist_profile;
DROP VIEW IF EXISTS v_beef_timeline;
DROP VIEW IF EXISTS v_sampling_relations;
DROP VIEW IF EXISTS v_playlist_detail;
DROP VIEW IF EXISTS v_playlist_tracks_expanded;
DROP VIEW IF EXISTS v_track_like_stats;
DROP VIEW IF EXISTS v_user_activity_summary;
DROP VIEW IF EXISTS v_recent_comments;


-- ------------------------------------------------------------
-- 1) v_track_detail
-- 트랙 + 앨범 + 메인 아티스트 정보 요약
--   - 트랙 상세 페이지, 일반 검색 결과 등에 사용
-- ------------------------------------------------------------
CREATE VIEW v_track_detail AS
SELECT
    t.track_id,
    t.title          AS track_title,
    t.album_id,
    a.title          AS album_title,
    t.release_date,
    a.main_artist_id,
    ma.main_artists  AS main_artists
FROM Track t
JOIN Album a
    ON t.album_id = a.album_id
LEFT JOIN (
    SELECT
        tar.track_id,
        GROUP_CONCAT(DISTINCT ar.name ORDER BY ar.name SEPARATOR ', ') AS main_artists
    FROM TrackArtistRole tar
    JOIN Artist ar
        ON ar.artist_id = tar.artist_id
    WHERE tar.role = 'MAIN'
    GROUP BY tar.track_id
) ma
    ON ma.track_id = t.track_id;


-- ------------------------------------------------------------
-- 2) v_track_with_tags
-- 트랙 + 태그(플로우/비트/테마) 요약
--   - 태그 기반 필터링/추천에 사용
-- ------------------------------------------------------------
CREATE VIEW v_track_with_tags AS
SELECT
    t.track_id,
    t.title AS track_title,
    GROUP_CONCAT(
        DISTINCT CONCAT('[', tg.tag_type, '] ', tg.name)
        ORDER BY tg.tag_type, tg.name
        SEPARATOR ', '
    ) AS tags_summary
FROM Track t
LEFT JOIN TrackTag tt
    ON tt.track_id = t.track_id
LEFT JOIN Tag tg
    ON tg.tag_id = tt.tag_id
GROUP BY
    t.track_id,
    t.title;


-- ------------------------------------------------------------
-- 3) v_artist_profile
-- 아티스트 + 장르 + 레이블 요약
--   - 아티스트 상세/검색 화면용
-- ------------------------------------------------------------
CREATE VIEW v_artist_profile AS
SELECT
    ar.artist_id,
    ar.name            AS artist_name,
    ar.country,
    ar.debut_year,
    -- 장르 요약
    GROUP_CONCAT(DISTINCT g.name ORDER BY g.name SEPARATOR ', ') AS genres,
    -- 레이블 요약 (연도 범위 포함)
    GROUP_CONCAT(
        DISTINCT CONCAT(lb.name,
                        ' (',
                        COALESCE(alb.from_year, '?'),
                        ' - ',
                        COALESCE(alb.to_year, '현재'),
                        ')')
        ORDER BY lb.name
        SEPARATOR ', '
    ) AS labels
FROM Artist ar
LEFT JOIN ArtistGenre ag
    ON ag.artist_id = ar.artist_id
LEFT JOIN Genre g
    ON g.genre_id = ag.genre_id
LEFT JOIN ArtistLabel alb
    ON alb.artist_id = ar.artist_id
LEFT JOIN Label lb
    ON lb.label_id = alb.label_id
GROUP BY
    ar.artist_id,
    ar.name,
    ar.country,
    ar.debut_year;


-- ------------------------------------------------------------
-- 4) v_beef_timeline
-- Beef + DissTrack + Track 정보를 합친 비프 타임라인
--   - Drake vs Kendrick 같은 비프 흐름을 시간순으로 조회할 때 사용
-- ------------------------------------------------------------
CREATE VIEW v_beef_timeline AS
SELECT
    b.beef_id,
    a1.name    AS artist_a,
    a2.name    AS artist_b,
    dt.track_id,
    tr.title   AS track_title,
    dt.side,          -- 'A' or 'B'
    dt.released_at
FROM Beef b
JOIN Artist a1
    ON a1.artist_id = b.artist_a_id
JOIN Artist a2
    ON a2.artist_id = b.artist_b_id
JOIN DissTrack dt
    ON dt.beef_id = b.beef_id
JOIN Track tr
    ON tr.track_id = dt.track_id;


-- ------------------------------------------------------------
-- 5) v_sampling_relations
-- Sample 관계를 사람이 읽기 좋은 형태로 변환
--   - source / target 트랙 제목과 함께 보여줌
-- ------------------------------------------------------------
CREATE VIEW v_sampling_relations AS
SELECT
    s.sample_id,
    s.sample_type,
    s.note,
    s.source_track_id,
    ts.title AS source_title,
    s.target_track_id,
    tt.title AS target_title
FROM Sample s
JOIN Track ts
    ON ts.track_id = s.source_track_id
JOIN Track tt
    ON tt.track_id = s.target_track_id;


-- ------------------------------------------------------------
-- 6) v_playlist_detail
-- 플레이리스트 메타 정보 + 곡 개수
--   - 플레이리스트 목록 화면에서 사용
-- ------------------------------------------------------------
CREATE VIEW v_playlist_detail AS
SELECT
    p.playlist_id,
    p.title,
    u.user_id,
    u.nickname           AS owner_nickname,
    p.is_public,
    p.created_at,
    COUNT(pt.track_id)   AS track_count
FROM Playlist p
JOIN User u
    ON u.user_id = p.user_id
LEFT JOIN PlaylistTrack pt
    ON pt.playlist_id = p.playlist_id
GROUP BY
    p.playlist_id,
    p.title,
    u.user_id,
    u.nickname,
    p.is_public,
    p.created_at;


-- ------------------------------------------------------------
-- 7) v_playlist_tracks_expanded
-- 플레이리스트별 트랙 리스트 상세
--   - 각 곡의 제목, 메인 아티스트, 정렬 순서를 함께 반환
-- ------------------------------------------------------------
CREATE VIEW v_playlist_tracks_expanded AS
SELECT
    p.playlist_id,
    p.title     AS playlist_title,
    u.nickname  AS owner_nickname,
    pt.track_order,
    t.track_id,
    t.title     AS track_title,
    ma.main_artists
FROM PlaylistTrack pt
JOIN Playlist p
    ON p.playlist_id = pt.playlist_id
JOIN User u
    ON u.user_id = p.user_id
JOIN Track t
    ON t.track_id = pt.track_id
LEFT JOIN (
    SELECT
        tar.track_id,
        GROUP_CONCAT(DISTINCT ar.name ORDER BY ar.name SEPARATOR ', ') AS main_artists
    FROM TrackArtistRole tar
    JOIN Artist ar
        ON ar.artist_id = tar.artist_id
    WHERE tar.role = 'MAIN'
    GROUP BY tar.track_id
) ma
    ON ma.track_id = t.track_id;


-- ------------------------------------------------------------
-- 8) v_track_like_stats
-- 곡별 좋아요 개수 집계
--   - 인기곡 정렬, 통계 등에 사용
-- ------------------------------------------------------------
CREATE VIEW v_track_like_stats AS
SELECT
    tl.track_id,
    COUNT(*) AS like_count
FROM TrackLike tl
GROUP BY
    tl.track_id;


-- ------------------------------------------------------------
-- 9) v_user_activity_summary
-- 유저별 활동 요약 (좋아요 수, 댓글 수, 플레이리스트 수)
--   - 유저 활동 분석, 마이페이지 요약 등에 사용
-- ------------------------------------------------------------
CREATE VIEW v_user_activity_summary AS
SELECT
    u.user_id,
    u.nickname,
    COALESCE(l.like_count, 0)      AS like_count,
    COALESCE(c.comment_count, 0)   AS comment_count,
    COALESCE(p.playlist_count, 0)  AS playlist_count
FROM User u
LEFT JOIN (
    SELECT user_id, COUNT(*) AS like_count
    FROM TrackLike
    GROUP BY user_id
) l
    ON l.user_id = u.user_id
LEFT JOIN (
    SELECT user_id, COUNT(*) AS comment_count
    FROM Comment
    GROUP BY user_id
) c
    ON c.user_id = u.user_id
LEFT JOIN (
    SELECT user_id, COUNT(*) AS playlist_count
    FROM Playlist
    GROUP BY user_id
) p
    ON p.user_id = u.user_id;


-- ------------------------------------------------------------
-- 10) v_recent_comments
-- 댓글 + 작성자 + 대상(곡/앨범/플리) 제목까지 함께 표시
--   - 커뮤니티/활동 피드 화면용
-- ------------------------------------------------------------
CREATE VIEW v_recent_comments AS
SELECT
    c.comment_id,
    c.user_id,
    u.nickname          AS author_nickname,
    c.target_type,
    c.target_id,
    CASE c.target_type
        WHEN 'track'    THEN t.title
        WHEN 'album'    THEN al.title
        WHEN 'playlist' THEN pl.title
        ELSE NULL
    END                 AS target_title,
    c.content,
    c.created_at
FROM Comment c
JOIN User u
    ON u.user_id = c.user_id
LEFT JOIN Track t
    ON t.track_id = c.target_id
    AND c.target_type = 'track'
LEFT JOIN Album al
    ON al.album_id = c.target_id
    AND c.target_type = 'album'
LEFT JOIN Playlist pl
    ON pl.playlist_id = c.target_id
    AND c.target_type = 'playlist';


-- ============================================
-- 뷰 정의 완료
-- ============================================
