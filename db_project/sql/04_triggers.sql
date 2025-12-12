-- ============================================
-- 04_triggers.sql (fixed)
-- ============================================

USE hiphopdb;

-- 기존 트리거가 있다면 먼저 삭제
DROP TRIGGER IF EXISTS trg_comment_log;
DROP TRIGGER IF EXISTS trg_tracklike_log;
DROP TRIGGER IF EXISTS trg_playlisttrack_auto_order;
DROP TRIGGER IF EXISTS trg_sample_prevent_cycle;
DROP TRIGGER IF EXISTS trg_disstrack_prevent_update;
DROP TRIGGER IF EXISTS trg_disstrack_prevent_delete;

-- 로그 테이블 (이미 있으면 그대로 둠)
CREATE TABLE IF NOT EXISTS CommentLog (
    log_id      INT AUTO_INCREMENT PRIMARY KEY,
    comment_id  INT,
    user_id     INT,
    target_type ENUM('track','album','playlist'),
    target_id   INT,
    created_at  DATETIME,
    log_time    DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS TrackLikeLog (
    log_id     INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT,
    track_id   INT,
    liked_at   DATETIME,
    log_time   DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

-- 1) Comment INSERT 시 로그
CREATE TRIGGER trg_comment_log
AFTER INSERT ON Comment
FOR EACH ROW
BEGIN
    INSERT INTO CommentLog (comment_id, user_id, target_type, target_id, created_at)
    VALUES (NEW.comment_id, NEW.user_id, NEW.target_type, NEW.target_id, NEW.created_at);
END$$


-- 2) TrackLike INSERT 시 로그
CREATE TRIGGER trg_tracklike_log
AFTER INSERT ON TrackLike
FOR EACH ROW
BEGIN
    INSERT INTO TrackLikeLog (user_id, track_id, liked_at)
    VALUES (NEW.user_id, NEW.track_id, NEW.liked_at);
END$$


-- 3) PlaylistTrack INSERT 시 track_order 자동 채우기
CREATE TRIGGER trg_playlisttrack_auto_order
BEFORE INSERT ON PlaylistTrack
FOR EACH ROW
BEGIN
    IF NEW.track_order IS NULL THEN
        SET NEW.track_order = (
            SELECT IFNULL(MAX(track_order), 0) + 1
            FROM PlaylistTrack
            WHERE playlist_id = NEW.playlist_id
        );
    END IF;
END$$


-- 4) Sample 관계에서 1-step 순환 방지
CREATE TRIGGER trg_sample_prevent_cycle
BEFORE INSERT ON Sample
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Sample
        WHERE source_track_id = NEW.target_track_id
          AND target_track_id = NEW.source_track_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '샘플링 관계에서 순환이 발생합니다. 입력이 차단되었습니다.';
    END IF;
END$$


-- 5) DissTrack 수정/삭제 금지
CREATE TRIGGER trg_disstrack_prevent_update
BEFORE UPDATE ON DissTrack
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'DissTrack 데이터는 수정할 수 없습니다.';
END$$

CREATE TRIGGER trg_disstrack_prevent_delete
BEFORE DELETE ON DissTrack
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'DissTrack 데이터는 삭제할 수 없습니다.';
END$$

DELIMITER ;
