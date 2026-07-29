<?php
$conn = new mysqli('127.0.0.1', 'root', '', 'minesec_lst', 3306);
if ($conn->connect_error) die("Connection failed: " . $conn->connect_error . "\n");

// assessments table
$conn->query("CREATE TABLE IF NOT EXISTS assessments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  visual_score DECIMAL(5,2) DEFAULT 0,
  auditory_score DECIMAL(5,2) DEFAULT 0,
  kinesthetic_score DECIMAL(5,2) DEFAULT 0,
  read_write_score DECIMAL(5,2) DEFAULT 0,
  learning_style VARCHAR(100) DEFAULT NULL,
  completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_student (student_id)
)");
echo "assessments table OK\n";

// results table (one row per student, ON DUPLICATE KEY UPDATE)
$conn->query("CREATE TABLE IF NOT EXISTS results (
  id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL UNIQUE,
  assessment_id INT DEFAULT NULL,
  learning_style VARCHAR(100) DEFAULT NULL,
  summary_en TEXT,
  summary_fr TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_student (student_id)
)");
echo "results table OK\n";

$conn->close();
echo "DONE!\n";
