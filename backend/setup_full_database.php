<?php
// ============================================================
//  MINESEC LST — Complete Schema Update & Account Pre-Registration
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- UPDATING DATABASE SCHEMA AND PRE-REGISTERING ALL ROLES ---\n";
    $pdo->exec("SET FOREIGN_KEY_CHECKS = 0;");

    // 0. ALLOW NULL ON PASSWORD_HASH FOR UNACTIVATED ACCOUNTS
    $pdo->exec("ALTER TABLE users MODIFY COLUMN password_hash VARCHAR(255) NULL;");
    $pdo->exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS security_code VARCHAR(255) NULL;");

    // 1. UPDATE STUDENTS TABLE SCHEMA
    $pdo->exec("ALTER TABLE students ADD COLUMN IF NOT EXISTS school_name VARCHAR(200) NULL;");
    $pdo->exec("ALTER TABLE students ADD COLUMN IF NOT EXISTS region VARCHAR(100) NULL;");
    $pdo->exec("ALTER TABLE students ADD COLUMN IF NOT EXISTS division VARCHAR(100) NULL;");
    $pdo->exec("ALTER TABLE students ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255) NULL;");
    $pdo->exec("ALTER TABLE students ADD COLUMN IF NOT EXISTS security_code VARCHAR(255) NULL;");

    // 2. UPDATE TEACHERS TABLE SCHEMA (Drop qualification, add school_name, region, division, password_hash, security_code)
    try {
        $pdo->exec("ALTER TABLE teachers DROP COLUMN qualification;");
    } catch (Exception $e) {
        // Column may already be dropped
    }

    $pdo->exec("ALTER TABLE teachers ADD COLUMN IF NOT EXISTS school_name VARCHAR(200) NULL;");
    $pdo->exec("ALTER TABLE teachers ADD COLUMN IF NOT EXISTS region VARCHAR(100) NULL;");
    $pdo->exec("ALTER TABLE teachers ADD COLUMN IF NOT EXISTS division VARCHAR(100) NULL;");
    $pdo->exec("ALTER TABLE teachers ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255) NULL;");
    $pdo->exec("ALTER TABLE teachers ADD COLUMN IF NOT EXISTS security_code VARCHAR(255) NULL;");

    // 3. Ensure School Exists
    $stmt = $pdo->prepare("SELECT id FROM schools WHERE code = 'LT_NGAOUNDAL'");
    $stmt->execute();
    $schoolId = $stmt->fetchColumn();

    if (!$schoolId) {
        $pdo->prepare("
            INSERT INTO schools (code, name, region, division, town)
            VALUES ('LT_NGAOUNDAL', 'LYCEE TECHNIQUE DE NGAOUNDAL', 'ADAMOUA', 'DJEREM', 'Ngaoundal')
        ")->execute();
        $schoolId = $pdo->lastInsertId();
    }

    $schoolName = 'LYCEE TECHNIQUE DE NGAOUNDAL';
    $region     = 'ADAMOUA';
    $division   = 'DJEREM';

    // Helper to insert or reset unactivated user
    $createUnactivatedUser = function($name, $email, $role, $phone) use ($pdo, $schoolId, $region, $division) {
        $stmt = $pdo->prepare("SELECT id FROM users WHERE phone = ? OR email = ?");
        $stmt->execute([$phone, $email]);
        $u = $stmt->fetch();

        if ($u) {
            $pdo->prepare("
                UPDATE users
                SET full_name = ?, role = ?, school_id = ?, region = ?, division = ?,
                    is_activated = 0, password_hash = NULL, security_code = NULL, phone = ?
                WHERE id = ?
            ")->execute([$name, $role, $schoolId, $region, $division, $phone, $u['id']]);
            return $u['id'];
        } else {
            $pdo->prepare("
                INSERT INTO users (full_name, email, role, phone, school_id, region, division, is_activated, is_active, password_hash, security_code)
                VALUES (?, ?, ?, ?, ?, ?, ?, 0, 1, NULL, NULL)
            ")->execute([$name, $email, $role, $phone, $schoolId, $region, $division]);
            return $pdo->lastInsertId();
        }
    };

    // ── A. PRE-REGISTER STUDENTS (UNACTIVATED) ───────────────────
    $s1Id = $createUnactivatedUser('Bello Oumarou', 'bello.o@student.cm', 'student', 'AD2026001');
    $pdo->prepare("DELETE FROM students WHERE user_id = ? OR mat_number = 'AD2026001'")->execute([$s1Id]);
    $pdo->prepare("
        INSERT INTO students (user_id, full_name, class_name, mat_number, gender, birth_date, school_name, region, division)
        VALUES (?, 'Bello Oumarou', '1ère TI', 'AD2026001', 'Male', '2007-03-12', ?, ?, ?)
    ")->execute([$s1Id, $schoolName, $region, $division]);

    $s2Id = $createUnactivatedUser('Amina Mohamadou', 'amina.m@student.cm', 'student', 'AD2026002');
    $pdo->prepare("DELETE FROM students WHERE user_id = ? OR mat_number = 'AD2026002'")->execute([$s2Id]);
    $pdo->prepare("
        INSERT INTO students (user_id, full_name, class_name, mat_number, gender, birth_date, school_name, region, division)
        VALUES (?, 'Amina Mohamadou', 'Terminale TI', 'AD2026002', 'Female', '2006-08-25', ?, ?, ?)
    ")->execute([$s2Id, $schoolName, $region, $division]);

    // ── B. PRE-REGISTER TEACHER (UNACTIVATED) ─────────────────────
    $tId = $createUnactivatedUser('M. Nguene Jacques', 'nguene.j@minesec.cm', 'teacher', 'T2026001');
    $pdo->prepare("DELETE FROM teachers WHERE user_id = ?")->execute([$tId]);
    $pdo->prepare("
        INSERT INTO teachers (user_id, staff_id, subject, class_name, school_name, region, division)
        VALUES (?, 'T2026001', 'Informatique', '1ère TI', ?, ?, ?)
    ")->execute([$tId, $schoolName, $region, $division]);

    // Ticked classes for Teacher
    $pdo->prepare("DELETE FROM teacher_classes WHERE teacher_id = ?")->execute([$tId]);
    $pdo->prepare("INSERT INTO teacher_classes (teacher_id, school_id, class_name) VALUES (?, ?, '1ère TI')")->execute([$tId, $schoolId]);
    $pdo->prepare("INSERT INTO teacher_classes (teacher_id, school_id, class_name) VALUES (?, ?, 'Terminale TI')")->execute([$tId, $schoolId]);

    // ── C. PRE-REGISTER PRINCIPAL (UNACTIVATED) ───────────────────
    $prnId = $createUnactivatedUser('Mme. Etoa Christine', 'etoa.c@minesec.cm', 'principal', 'PRN202601');

    // ── D. PRE-REGISTER DIVISIONAL DELEGATE (UNACTIVATED) ─────────
    $delId = $createUnactivatedUser('M. Bikoi Joseph', 'bikoi.j@minesec.cm', 'divisional_delegate', 'DEL202601');

    // ── E. PRE-REGISTER REGIONAL DELEGATE (UNACTIVATED) ───────────
    $regId = $createUnactivatedUser('Dr. Fouda Alphonse', 'fouda.a@minesec.cm', 'regional_delegate', 'REG202601');

    // ── F. PRE-REGISTER MINESEC ADMIN (UNACTIVATED) ───────────────
    $admId = $createUnactivatedUser('MINESEC Inspector General', 'admin@minesec.cm', 'admin', 'ADM202601');

    echo "SUCCESS: Database schema updated and all roles pre-registered (UNACTIVATED):\n";
    echo "• Student 1: AD2026001  (Bello Oumarou)         | School: $schoolName | Region: $region | Division: $division\n";
    echo "• Student 2: AD2026002  (Amina Mohamadou)       | School: $schoolName | Region: $region | Division: $division\n";
    echo "• Teacher:   T2026001   (M. Nguene Jacques)     | School: $schoolName | Region: $region | Division: $division\n";
    echo "• Principal: PRN202601  (Mme. Etoa Christine)   | School: $schoolName | Region: $region | Division: $division\n";
    echo "• Div. Del:  DEL202601  (M. Bikoi Joseph)       | Region: $region | Division: $division\n";
    echo "• Reg. Del:  REG202601  (Dr. Fouda Alphonse)    | Region: $region\n";
    echo "• Admin:     ADM202601  (MINESEC Inspector Gen) | National Scope\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
