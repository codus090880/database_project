-- ============================================
-- 01_create_tables.sql
-- 외힙 메타데이터 DB 테이블 생성 스크립트
-- ============================================

-- 순서: FK 의존도 낮은 테이블부터 생성

-- 1) User
CREATE TABLE User (
    user_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nickname      VARCHAR(50)  NOT NULL,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    role          ENUM('user', 'admin') NOT NULL DEFAULT 'user'
) ENGINE=InnoDB;

-- 2) Artist
CREATE TABLE Artist (
    artist_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name             VARCHAR(100) NOT NULL,
    country          VARCHAR(50),
    debut_year       YEAR,
    profile_img_url  VARCHAR(255),
    note             TEXT
) ENGINE=InnoDB;

-- 3) Label
CREATE TABLE Label (
    label_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    country      VARCHAR(50),
    founded_year YEAR
) ENGINE=InnoDB;

-- 4) Crew
CREATE TABLE Crew (
    crew_id  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name     VARCHAR(100) NOT NULL,
    country  VARCHAR(50),
    note     TEXT
) ENGINE=InnoDB;

-- 5) Producer
CREATE TABLE Producer (
    producer_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    country     VARCHAR(50),
    note        TEXT
) ENGINE=InnoDB;

-- 6) Genre
CREATE TABLE Genre (
    genre_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name     VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- 7) Tag
CREATE TABLE Tag (
    tag_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name     VARCHAR(100) NOT NULL,
    tag_type ENUM('flow_type', 'beat_type', 'theme') NOT NULL
) ENGINE=InnoDB;

-- 8) ArtistLabel (Artist - Label M:N, 기간 이력)
CREATE TABLE ArtistLabel (
    artist_id INT UNSIGNED NOT NULL,
    label_id  INT UNSIGNED NOT NULL,
    from_year YEAR,
    to_year   YEAR,
    PRIMARY KEY (artist_id, label_id),
    CONSTRAINT fk_artistlabel_artist
        FOREIGN KEY (artist_id) REFERENCES Artist(artist_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_artistlabel_label
        FOREIGN KEY (label_id) REFERENCES Label(label_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 9) ArtistCrew (Artist - Crew M:N, 기간 이력)
CREATE TABLE ArtistCrew (
    artist_id INT UNSIGNED NOT NULL,
    crew_id   INT UNSIGNED NOT NULL,
    from_year YEAR,
    to_year   YEAR,
    PRIMARY KEY (artist_id, crew_id),
    CONSTRAINT fk_artistcrew_artist
        FOREIGN KEY (artist_id) REFERENCES Artist(artist_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_artistcrew_crew
        FOREIGN KEY (crew_id) REFERENCES Crew(crew_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 10) Album
CREATE TABLE Album (
    album_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    main_artist_id  INT UNSIGNED NOT NULL,
    title           VARCHAR(200) NOT NULL,
    release_date    DATE,
    album_type      ENUM('LP', 'EP', 'Single', 'Mixtape', 'Other') NOT NULL DEFAULT 'Other',
    cover_img_url   VARCHAR(255),
    CONSTRAINT fk_album_main_artist
        FOREIGN KEY (main_artist_id) REFERENCES Artist(artist_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 11) Track
CREATE TABLE Track (
    track_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    album_id      INT UNSIGNED NOT NULL,
    title         VARCHAR(200) NOT NULL,
    track_no      INT,
    duration_sec  INT,
    explicit_flag TINYINT(1) NOT NULL DEFAULT 0,
    release_date  DATE,
    CONSTRAINT fk_track_album
        FOREIGN KEY (album_id) REFERENCES Album(album_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 12) TrackArtistRole (곡-아티스트 역할)
CREATE TABLE TrackArtistRole (
    track_id  INT UNSIGNED NOT NULL,
    artist_id INT UNSIGNED NOT NULL,
    role      ENUM('MAIN', 'FEAT', 'VOCAL', 'PRODUCER', 'OTHER') NOT NULL,
    PRIMARY KEY (track_id, artist_id, role),
    CONSTRAINT fk_tar_track
        FOREIGN KEY (track_id) REFERENCES Track(track_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_tar_artist
        FOREIGN KEY (artist_id) REFERENCES Artist(artist_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 13) TrackProducer (곡-프로듀서 M:N)
CREATE TABLE TrackProducer (
    track_id    INT UNSIGNED NOT NULL,
    producer_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (track_id, producer_id),
    CONSTRAINT fk_trackproducer_track
        FOREIGN KEY (track_id) REFERENCES Track(track_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_trackproducer_producer
        FOREIGN KEY (producer_id) REFERENCES Producer(producer_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 14) ArtistGenre (Artist - Genre M:N)
CREATE TABLE ArtistGenre (
    artist_id INT UNSIGNED NOT NULL,
    genre_id  INT UNSIGNED NOT NULL,
    PRIMARY KEY (artist_id, genre_id),
    CONSTRAINT fk_artistgenre_artist
        FOREIGN KEY (artist_id) REFERENCES Artist(artist_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_artistgenre_genre
        FOREIGN KEY (genre_id) REFERENCES Genre(genre_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 15) TrackTag (Track - Tag M:N)
CREATE TABLE TrackTag (
    track_id INT UNSIGNED NOT NULL,
    tag_id   INT UNSIGNED NOT NULL,
    PRIMARY KEY (track_id, tag_id),
    CONSTRAINT fk_tracktag_track
        FOREIGN KEY (track_id) REFERENCES Track(track_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_tracktag_tag
        FOREIGN KEY (tag_id) REFERENCES Tag(tag_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 16) Sample (샘플링 관계)
CREATE TABLE Sample (
    sample_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    source_track_id  INT UNSIGNED NOT NULL,
    target_track_id  INT UNSIGNED NOT NULL,
    sample_type      VARCHAR(50),
    note             TEXT,
    CONSTRAINT fk_sample_source
        FOREIGN KEY (source_track_id) REFERENCES Track(track_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_sample_target
        FOREIGN KEY (target_track_id) REFERENCES Track(track_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 17) Beef (아티스트 간 비프)
CREATE TABLE Beef (
    beef_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    artist_a_id  INT UNSIGNED NOT NULL,
    artist_b_id  INT UNSIGNED NOT NULL,
    start_year   YEAR,
    end_year     YEAR,
    description  TEXT,
    CONSTRAINT fk_beef_artist_a
        FOREIGN KEY (artist_a_id) REFERENCES Artist(artist_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_beef_artist_b
        FOREIGN KEY (artist_b_id) REFERENCES Artist(artist_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 18) DissTrack (비프에 속한 디스트랙)
CREATE TABLE DissTrack (
    beef_id     INT UNSIGNED NOT NULL,
    track_id    INT UNSIGNED NOT NULL,
    side        ENUM('A', 'B') NOT NULL,
    released_at DATE,
    PRIMARY KEY (beef_id, track_id),
    CONSTRAINT fk_disstrack_beef
        FOREIGN KEY (beef_id) REFERENCES Beef(beef_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_disstrack_track
        FOREIGN KEY (track_id) REFERENCES Track(track_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 19) Playlist
CREATE TABLE Playlist (
    playlist_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id     INT UNSIGNED NOT NULL,
    title       VARCHAR(200) NOT NULL,
    description TEXT,
    is_public   TINYINT(1) NOT NULL DEFAULT 1,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_playlist_user
        FOREIGN KEY (user_id) REFERENCES User(user_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 20) PlaylistTrack (플레이리스트 - 곡 관계)
CREATE TABLE PlaylistTrack (
    playlist_id INT UNSIGNED NOT NULL,
    track_id    INT UNSIGNED NOT NULL,
    track_order INT NOT NULL,
    PRIMARY KEY (playlist_id, track_id),
    CONSTRAINT fk_playlisttrack_playlist
        FOREIGN KEY (playlist_id) REFERENCES Playlist(playlist_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_playlisttrack_track
        FOREIGN KEY (track_id) REFERENCES Track(track_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 21) TrackLike (사용자-곡 좋아요)
CREATE TABLE TrackLike (
    user_id   INT UNSIGNED NOT NULL,
    track_id  INT UNSIGNED NOT NULL,
    liked_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, track_id),
    CONSTRAINT fk_tracklike_user
        FOREIGN KEY (user_id) REFERENCES User(user_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_tracklike_track
        FOREIGN KEY (track_id) REFERENCES Track(track_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 22) Comment (트랙/앨범/플레이리스트 댓글)
CREATE TABLE Comment (
    comment_id  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id     INT UNSIGNED NOT NULL,
    target_type ENUM('track', 'album', 'playlist') NOT NULL,
    target_id   INT UNSIGNED NOT NULL,
    content     TEXT NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comment_user
        FOREIGN KEY (user_id) REFERENCES User(user_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;
