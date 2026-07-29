<?php
$conn = new mysqli('127.0.0.1', 'root', '', 'minesec_lst', 3306);
if ($conn->connect_error) die("Connection failed: " . $conn->connect_error . "\n");

// Reset BOTH students to NOT activated
$conn->query("SET FOREIGN_KEY_CHECKS = 0");
$conn->query("DELETE FROM students");
$conn->query("DELETE FROM users WHERE role = 'student'");
$conn->query("SET FOREIGN_KEY_CHECKS = 1");

// Student 1 - NOT activated
$conn->query("INSERT INTO users (full_name, email, password_hash, role, school_id, region, division, is_activated, is_active, created_at)
VALUES ('Bello Oumarou', NULL, '', 'student', 1, 'ADAMOUA', 'DJEREM', 0, 1, NOW())");
$s1Id = $conn->insert_id;
$conn->query("INSERT INTO students (user_id, full_name, mat_number, class_name, birth_date, gender)
VALUES ($s1Id, 'Bello Oumarou', 'AD2026001', '1ère TI', '2007-03-12', 'Male')");

// Student 2 - ALSO NOT activated
$conn->query("INSERT INTO users (full_name, email, password_hash, role, school_id, region, division, is_activated, is_active, created_at)
VALUES ('Amina Mohamadou', NULL, '', 'student', 1, 'ADAMOUA', 'DJEREM', 0, 1, NOW())");
$s2Id = $conn->insert_id;
$conn->query("INSERT INTO students (user_id, full_name, mat_number, class_name, birth_date, gender)
VALUES ($s2Id, 'Amina Mohamadou', 'AD2026002', 'Terminale TI', '2006-08-25', 'Female')");

// Verify
$res = $conn->query("SELECT s.full_name, s.mat_number, s.class_name, u.is_activated FROM students s JOIN users u ON u.id = s.user_id");
echo "--- STUDENTS (All NOT Activated) ---\n";
while ($row = $res->fetch_assoc()) {
    $status = $row['is_activated'] ? 'ACTIVATED' : 'NOT ACTIVATED';
    echo "Name: {$row['full_name']} | Mat: {$row['mat_number']} | Class: {$row['class_name']} | Status: $status\n";
}
$conn->close();
echo "DONE!\n";
