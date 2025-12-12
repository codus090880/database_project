-- ============================================
-- 00_create_database.sql
-- 외힙(힙합) 음악 플랫폼 프로젝트용 데이터베이스 생성 스크립트
-- ============================================

-- 기존 DB가 있다면 삭제 
DROP DATABASE IF EXISTS hiphopdb;

-- 새 데이터베이스 생성
CREATE DATABASE hiphopdb
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_0900_ai_ci;

-- 생성한 DB 사용
USE hiphopdb;

-- 확인
SELECT DATABASE() AS current_database;
