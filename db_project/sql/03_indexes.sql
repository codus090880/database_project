-- ============================================
-- 03_indexes.sql
-- 외힙 메타데이터 DB 인덱스 최적화 스크립트
-- ============================================

-- 1) Artist 검색 최적화 -----------------------------------------
-- 아티스트 이름 기반 검색이 매우 빈번함.
CREATE INDEX idx_artist_name ON Artist(name);


-- 2) Album 검색 최적화 ------------------------------------------
-- 메인 아티스트별 앨범 조회를 빠르게 하기 위함.
CREATE INDEX idx_album_main_artist ON Album(main_artist_id);

-- 앨범 제목 검색 속도 향상
CREATE INDEX idx_album_title ON Album(title);


-- 3) Track 검색 최적화 ------------------------------------------
-- 특정 앨범의 트랙 목록 조회가 잦음.
CREATE INDEX idx_track_album ON Track(album_id);

-- 트랙명 검색 최적화
CREATE INDEX idx_track_title ON Track(title);

-- 발매일 순 정렬을 위한 인덱스
CREATE INDEX idx_track_release_date ON Track(release_date);


-- 4) TrackArtistRole 성능 향상 -----------------------------------
-- “피처링/참여 아티스트로 곡 찾기”가 핵심 기능.
CREATE INDEX idx_tar_artist ON TrackArtistRole(artist_id);
CREATE INDEX idx_tar_track ON TrackArtistRole(track_id);

-- 역할(role) 필터링 (MAIN / FEAT / PRODUCER 등)
CREATE INDEX idx_tar_role ON TrackArtistRole(role);


-- 5) TrackProducer ------------------------------------------------
-- 특정 프로듀서가 만든 곡을 빠르게 조회하기 위해.
CREATE INDEX idx_trackproducer_producer ON TrackProducer(producer_id);
CREATE INDEX idx_trackproducer_track ON TrackProducer(track_id);


-- 6) ArtistGenre --------------------------------------------------
-- 특정 장르의 대표 아티스트 찾기.
CREATE INDEX idx_artistgenre_genre ON ArtistGenre(genre_id);


-- 7) TrackTag -----------------------------------------------------
-- 태그 기반 필터링(비트/플로우/테마별 탐색) 최적화.
CREATE INDEX idx_tracktag_tag ON TrackTag(tag_id);
CREATE INDEX idx_tracktag_track ON TrackTag(track_id);


-- 8) Sample (샘플링 구조) ---------------------------------------
-- 특정 트랙이 누구를 샘플링했는지 or 누구에게 샘플링되었는지 빠르게 조회.
CREATE INDEX idx_sample_source ON Sample(source_track_id);
CREATE INDEX idx_sample_target ON Sample(target_track_id);


-- 9) Beef ---------------------------------------------------------
-- 비프에 참여한 아티스트 기반 조회.
CREATE INDEX idx_beef_artist_a ON Beef(artist_a_id);
CREATE INDEX idx_beef_artist_b ON Beef(artist_b_id);


-- 10) DissTrack ---------------------------------------------------
-- 비프 타임라인 조회(ORDER BY released_at).
CREATE INDEX idx_disstrack_beef ON DissTrack(beef_id);
CREATE INDEX idx_disstrack_released_at ON DissTrack(released_at);


-- 11) Playlist ----------------------------------------------------
-- 사용자별 플레이리스트 조회 속도 향상.
CREATE INDEX idx_playlist_user ON Playlist(user_id);

-- 제목 검색
CREATE INDEX idx_playlist_title ON Playlist(title);


-- 12) PlaylistTrack ----------------------------------------------
-- 특정 플레이리스트의 트랙 리스트 조회 최적화.
CREATE INDEX idx_playlisttrack_playlist ON PlaylistTrack(playlist_id);
CREATE INDEX idx_playlisttrack_track ON PlaylistTrack(track_id);


-- 13) TrackLike ---------------------------------------------------
-- 사용자별 좋아요 / 곡별 좋아요 수 집계에 유용.
CREATE INDEX idx_tracklike_user ON TrackLike(user_id);
CREATE INDEX idx_tracklike_track ON TrackLike(track_id);


-- 14) Comment -----------------------------------------------------
-- 최신 댓글 조회, 특정 대상의 댓글 탐색.
CREATE INDEX idx_comment_target_type ON Comment(target_type);
CREATE INDEX idx_comment_target_id ON Comment(target_id);
CREATE INDEX idx_comment_user ON Comment(user_id);
CREATE INDEX idx_comment_created_at ON Comment(created_at);


-- ============================================
-- 인덱스 생성 완료
-- ============================================
