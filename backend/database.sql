-- ============================================================
--  MINESEC LST  |  MySQL Database Schema
--  Ministry of Secondary Education — Cameroon
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

-- Drop existing tables if they exist to avoid type mismatch errors
DROP TABLE IF EXISTS assessment_answers;
DROP TABLE IF EXISTS assessments;
DROP TABLE IF EXISTS results;
DROP TABLE IF EXISTS recommendations;
DROP TABLE IF EXISTS options;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS questionnaires;
DROP TABLE IF EXISTS activation_codes;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS teachers;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS schools;

-- ─────────────────────────────────────────────────────────────
--  SCHOOLS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE schools (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code        VARCHAR(20)  NOT NULL UNIQUE,
    name        VARCHAR(200) NOT NULL,
    region      VARCHAR(100) NOT NULL,
    division    VARCHAR(100) NOT NULL,
    town        VARCHAR(100),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────────────────────────
--  USERS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE users (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(150) NOT NULL,
    email           VARCHAR(200) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    role            VARCHAR(50) NOT NULL,
    phone           VARCHAR(20),
    school_id       INT UNSIGNED NULL,
    region          VARCHAR(100),
    division        VARCHAR(100),
    activation_code VARCHAR(20) UNIQUE,
    is_activated    TINYINT(1) DEFAULT 0,
    is_active       TINYINT(1) DEFAULT 1,
    last_login      TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────────────────────────
--  STUDENTS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE students (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id     INT UNSIGNED NOT NULL UNIQUE,
    class_name  VARCHAR(50)  NOT NULL,
    mat_number  VARCHAR(50),
    gender      VARCHAR(20),
    birth_date  DATE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────────────────────────
--  TEACHERS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE teachers (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id       INT UNSIGNED NOT NULL UNIQUE,
    staff_id      VARCHAR(50) UNIQUE,
    subject       VARCHAR(100),
    qualification VARCHAR(200),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────────────────────────
--  QUESTIONNAIRES & QUESTIONS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE questionnaires (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title_en   VARCHAR(300) NOT NULL,
    title_fr   VARCHAR(300) NOT NULL,
    is_active  TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE questions (
    id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    questionnaire_id  INT UNSIGNED NOT NULL,
    text_en           TEXT NOT NULL,
    text_fr           TEXT NOT NULL,
    category          VARCHAR(50) NOT NULL,
    order_num         INT UNSIGNED DEFAULT 0,
    FOREIGN KEY (questionnaire_id) REFERENCES questionnaires(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE options (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    question_id INT UNSIGNED NOT NULL,
    text_en     VARCHAR(500) NOT NULL,
    text_fr     VARCHAR(500) NOT NULL,
    score       TINYINT UNSIGNED NOT NULL DEFAULT 0,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────────────────────────
--  ASSESSMENTS & RESULTS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE assessments (
    id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id        INT UNSIGNED NOT NULL,
    questionnaire_id  INT UNSIGNED NOT NULL,
    visual_score      DECIMAL(5,2) DEFAULT 0,
    auditory_score    DECIMAL(5,2) DEFAULT 0,
    kinesthetic_score DECIMAL(5,2) DEFAULT 0,
    learning_style    VARCHAR(50),
    completed_at      TIMESTAMP NULL,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (questionnaire_id) REFERENCES questionnaires(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE assessment_answers (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    assessment_id INT UNSIGNED NOT NULL,
    question_id   INT UNSIGNED NOT NULL,
    option_id     INT UNSIGNED NOT NULL,
    FOREIGN KEY (assessment_id) REFERENCES assessments(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (option_id) REFERENCES options(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE results (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id     INT UNSIGNED NOT NULL UNIQUE,
    assessment_id  INT UNSIGNED NOT NULL,
    learning_style VARCHAR(50) NOT NULL,
    summary_en     TEXT,
    summary_fr     TEXT,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (assessment_id) REFERENCES assessments(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────────────────────────
--  ACTIVATION CODES
-- ─────────────────────────────────────────────────────────────
CREATE TABLE activation_codes (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code       VARCHAR(20) NOT NULL UNIQUE,
    role       VARCHAR(50) NOT NULL,
    school_id  INT UNSIGNED NULL,
    used_by    INT UNSIGNED NULL,
    used_at    TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id),
    FOREIGN KEY (used_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- SEED DATA
INSERT INTO users (full_name, email, password_hash, role, is_activated, is_active)
VALUES ('MINESEC Administrator', 'admin@minesec.cm', SHA2('Admin@MINESEC2025!', 256), 'admin', 1, 1);

-- Add security_code column (run if upgrading existing DB)
ALTER TABLE users ADD COLUMN IF NOT EXISTS security_code VARCHAR(255) NULL AFTER password_hash;
