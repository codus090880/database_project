-- ============================================
-- 06_procedures.sql
-- 외힙 메타데이터 DB 저장 프로시저 정의 스크립트
-- ============================================

USE hiphopdb;

-- 기존 프로시저가 있다면 먼저 삭제 (여러 번 실행해도 안전)
DROP PROCEDURE IF EXISTS sp_get_tracks_by_artist;
DROP PROCEDURE IF EXISTS sp_get_beef_timeline;
DROP PROCEDURE IF EXISTS sp_add_track_like_safe;
DROP PROCEDURE IF EXISTS sp_get_track_like_count;

DELIMITER $$

-- ------------------------------------------------------------
-- 1) sp_get_tracks_by_artist
--   - 입력: 아티스트 이름 (부분 검색)
--   - 출력: 해당 아티스트가 MAIN 으로 참여한 트랙 목록
--   - 특징: JOIN + LIKE 조건 → Oracle의 SELECT문과 구조 동일
--   사용 예:
--   CALL sp_get_tracks_by_artist('Kendrick');
-- ------------------------------------------------------------
CREATE PROCEDURE sp_get_tracks_by_artist (
    IN p_artist_name VARCHAR(100)
)
BEGIN
    SELECT
        ar.artist_id,
        ar.name        AS artist_name,
        t.track_id,
        t.title        AS track_title,
        t.release_date,
        a.album_id,
        a.title        AS album_title
    FROM Artist ar
    JOIN TrackArtistRole tar
        ON tar.artist_id = ar.artist_id
       AND tar.role = 'MAIN'
    JOIN Track t
        ON t.track_id = tar.track_id
    JOIN Album a
        ON a.album_id = t.album_id
    WHERE ar.name LIKE CONCAT('%', p_artist_name, '%')
    ORDER BY t.release_date, t.title;
END$$


-- ------------------------------------------------------------
-- 2) sp_get_beef_timeline
--   - 입력: beef_id
--   - 출력: 해당 비프의 디스트랙 타임라인 (시간순)
--   - 특징: View(v_beef_timeline)를 이용해서 Oracle에서도
--           거의 동일한 구조로 작성 가능
--   사용 예:
--   CALL sp_get_beef_timeline(1);
-- ------------------------------------------------------------
CREATE PROCEDURE sp_get_beef_timeline (
    IN p_beef_id INT
)
BEGIN
    SELECT
        beef_id,
        artist_a,
        artist_b,
        track_id,
        track_title,
        side,
        released_at
    FROM v_beef_timeline
    WHERE beef_id = p_beef_id
    ORDER BY released_at;
END$$


-- ------------------------------------------------------------
-- 3) sp_add_track_like_safe
--   - 입력: user_id, track_id
--   - 동작:
--       1) User/Track 존재 여부 확인
--       2) 이미 좋아요 한 경우 에러 발생
--       3) 이상 없으면 TrackLike 에 INSERT
--          (트리거 trg_tracklike_log 가 자동으로 로그를 남김)
--   - 특징: Oracle PL/SQL에서의 예외 처리/검증 로직과 비교하기 좋음
--   사용 예:
--   CALL sp_add_track_like_safe(1, 13);
-- ------------------------------------------------------------
CREATE PROCEDURE sp_add_track_like_safe (
    IN p_user_id  INT UNSIGNED,
    IN p_track_id INT UNSIGNED
)
BEGIN
    DECLARE v_cnt INT DEFAULT 0;

    -- 1) User 존재 여부 확인
    SELECT COUNT(*) INTO v_cnt
    FROM User
    WHERE user_id = p_user_id;

    IF v_cnt = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '존재하지 않는 사용자입니다.';
    END IF;

    -- 2) Track 존재 여부 확인
    SELECT COUNT(*) INTO v_cnt
    FROM Track
    WHERE track_id = p_track_id;

    IF v_cnt = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '존재하지 않는 트랙입니다.';
    END IF;

    -- 3) 이미 좋아요 했는지 확인
    SELECT COUNT(*) INTO v_cnt
    FROM TrackLike
    WHERE user_id = p_user_id
      AND track_id = p_track_id;

    IF v_cnt > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '이미 좋아요한 트랙입니다.';
    END IF;

    -- 4) 실제 INSERT (트리거가 로그 기록)
    INSERT INTO TrackLike (user_id, track_id)
    VALUES (p_user_id, p_track_id);
END$$


-- ------------------------------------------------------------
-- 4) sp_get_track_like_count
--   - 입력: track_id (IN)
--   - 출력: like 개수 (OUT)
--   - 특징: Oracle의 OUT 파라미터와 비교하기 좋은 예제
--   사용 예:
--   SET @like_cnt = 0;
--   CALL sp_get_track_like_count(13, @like_cnt);
--   SELECT @like_cnt;
-- ------------------------------------------------------------
CREATE PROCEDURE sp_get_track_like_count (
    IN  p_track_id    INT UNSIGNED,
    OUT p_like_count  INT
)
BEGIN
    SELECT COUNT(*)
    INTO p_like_count
    FROM TrackLike
    WHERE track_id = p_track_id;
END$$

DELIMITER ;

-- ============================================
-- 프로시저 정의 완료
-- ============================================
