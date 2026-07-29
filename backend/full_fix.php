<?php
// Direct connection using mysqli (bypasses PDO config issues)
$conn = new mysqli('127.0.0.1', 'root', '', 'minesec_lst', 3306);
if ($conn->connect_error) die("Connection failed: " . $conn->connect_error . "\n");

echo "Connected successfully.\n";

$queries = [
    // Fix users table
    "ALTER TABLE users MODIFY COLUMN email VARCHAR(200) NULL",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS security_code VARCHAR(255) NULL AFTER password_hash",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS activated_at TIMESTAMP NULL AFTER is_activated",
    // Fix students table
    "ALTER TABLE students ADD COLUMN IF NOT EXISTS full_name VARCHAR(150) NOT NULL DEFAULT '' AFTER user_id",
    // Delete old students
    "SET FOREIGN_KEY_CHECKS = 0",
    "DELETE FROM students",
    "DELETE FROM users WHERE role = 'student'",
    "SET FOREIGN_KEY_CHECKS = 1",
    // Ensure school exists
    "INSERT IGNORE INTO schools (id, code, name, region, division, town) VALUES (1, 'LT_NGAOUNDAL', 'LYCEE TECHNIQUE DE NGAOUNDAL', 'ADAMOUA', 'DJEREM', 'Ngaoundal')",
    // Student 1 - Unactivated
    "INSERT INTO users (full_name, email, password_hash, role, school_id, region, division, is_activated, is_active, created_at) VALUES ('Bello Oumarou', NULL, '', 'student', 1, 'ADAMOUA', 'DJEREM', 0, 1, NOW())",
];

foreach ($queries as $q) {
    if ($conn->query($q) === TRUE) {
        echo "OK: " . substr($q, 0, 60) . "\n";
    } else {
        echo "ERR: " . $conn->error . " | SQL: " . substr($q, 0, 60) . "\n";
    }
}

// Insert student 1 record
$s1Id = $conn->insert_id;
if (!$s1Id) {
    // get last student user id
    $r = $conn->query("SELECT id FROM users WHERE role='student' ORDER BY id DESC LIMIT 1");
    $s1Id = $r->fetch_row()[0];
}
$conn->query("INSERT INTO students (user_id, full_name, mat_number, class_name, birth_date, gender) VALUES ($s1Id, 'Bello Oumarou', 'AD2026001', '1ère TI', '2007-03-12', 'Male')");
echo "Student 1 inserted: Bello Oumarou (user_id=$s1Id)\n";

// Student 2 - Activated
$p = hash('sha256', 'password123');
$pin = hash('sha256', '1234');
$conn->query("INSERT INTO users (full_name, email, password_hash, security_code, role, school_id, region, division, is_activated, activated_at, is_active, created_at) VALUES ('Amina Mohamadou', NULL, '$p', '$pin', 'student', 1, 'ADAMOUA', 'DJEREM', 1, NOW(), 1, NOW())");
$s2Id = $conn->insert_id;
$conn->query("INSERT INTO students (user_id, full_name, mat_number, class_name, birth_date, gender) VALUES ($s2Id, 'Amina Mohamadou', 'AD2026002', 'Terminale TI', '2006-08-25', 'Female')");
echo "Student 2 inserted: Amina Mohamadou (user_id=$s2Id)\n";

// Verify
echo "\n--- FINAL students TABLE ---\n";
$res = $conn->query("SELECT s.id, s.full_name, s.mat_number, s.class_name, s.gender, s.birth_date FROM students s");
while ($row = $res->fetch_assoc()) {
    echo "ID:{$row['id']} | Name:{$row['full_name']} | Mat:{$row['mat_number']} | Class:{$row['class_name']} | Gender:{$row['gender']} | DOB:{$row['birth_date']}\n";
}
$conn->close();
echo "\nDONE!\n";
