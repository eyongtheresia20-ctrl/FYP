import shutil

# Step 1: Add is_active column to schools table
php_alter_script = """<?php
require_once 'c:/Users/COUNTESS/Desktop/FYP/backend/config/database.php';
$pdo = getDB();

try {
    $pdo->exec("ALTER TABLE schools ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER town");
    echo "SUCCESS: Added is_active column to schools table\\n";
} catch (Exception $e) {
    echo "NOTE: Column might already exist: " . $e->getMessage() . "\\n";
}
"""

with open(r'scratch/alter_schools_table.php', 'w', encoding='utf-8') as f:
    f.write(php_alter_script)

# Step 2: Update backend/api/admin.php with school management CRUD actions
with open(r'backend/api/admin.php', 'r', encoding='utf-8') as f:
    code = f.read()

# Add CRUD cases to admin.php
school_crud_cases = """    // ── 9. ADD SCHOOL ──────────────────────────────────────────
    case 'add_school':
        $schoolName = trim($body['name'] ?? $body['school_name'] ?? '');
        $region     = trim($body['region'] ?? 'ADAMOUA');
        $division   = trim($body['division'] ?? 'DJEREM');
        $town       = trim($body['town'] ?? '');
        $code       = trim($body['code'] ?? 'SCH' . str_pad(rand(10, 999), 3, '0', STR_PAD_LEFT));

        if (empty($schoolName)) respondError('School name is required.');

        // Check duplicate
        $stmtCheck = $pdo->prepare("SELECT id FROM schools WHERE LOWER(name) = LOWER(?)");
        $stmtCheck->execute([$schoolName]);
        if ($stmtCheck->fetch()) {
            respondError("A school with the name '$schoolName' already exists.");
        }

        $stmt = $pdo->prepare("INSERT INTO schools (code, name, region, division, town, is_active, created_at) VALUES (?, ?, ?, ?, ?, 1, NOW())");
        $stmt->execute([$code, $schoolName, $region, $division, $town]);
        $newId = $pdo->lastInsertId();

        respond(true, "School '$schoolName' registered successfully.", [
            'id' => $newId,
            'name' => $schoolName,
            'region' => $region,
            'division' => $division,
            'town' => $town,
            'is_active' => 1
        ]);
        break;

    // ── 10. UPDATE / MODIFY SCHOOL ──────────────────────────────
    case 'update_school':
    case 'edit_school':
        $schoolId   = intval($body['id'] ?? $body['school_id'] ?? 0);
        $schoolName = trim($body['name'] ?? $body['school_name'] ?? '');
        $region     = trim($body['region'] ?? 'ADAMOUA');
        $division   = trim($body['division'] ?? 'DJEREM');
        $town       = trim($body['town'] ?? '');

        if ($schoolId <= 0 && !empty($schoolName)) {
            // Find by name if id not sent
            $stmtFind = $pdo->prepare("SELECT id FROM schools WHERE LOWER(name) = LOWER(?)");
            $stmtFind->execute([$schoolName]);
            $schoolId = intval($stmtFind->fetchColumn());
        }

        if ($schoolId <= 0 || empty($schoolName)) {
            respondError('Valid School ID and School Name are required.');
        }

        // Get old name for cascading user/student/teacher records
        $stmtOld = $pdo->prepare("SELECT name FROM schools WHERE id = ?");
        $stmtOld->execute([$schoolId]);
        $oldSchoolName = $stmtOld->fetchColumn();

        $stmt = $pdo->prepare("UPDATE schools SET name = ?, region = ?, division = ?, town = ? WHERE id = ?");
        $stmt->execute([$schoolName, $region, $division, $town, $schoolId]);

        // Cascade school name update to users and sub-tables
        if ($oldSchoolName && $oldSchoolName !== $schoolName) {
            $pdo->prepare("UPDATE users SET school_name = ? WHERE school_name = ?")->execute([$schoolName, $oldSchoolName]);
            $pdo->prepare("UPDATE students SET school_name = ? WHERE school_name = ?")->execute([$schoolName, $oldSchoolName]);
            $pdo->prepare("UPDATE teachers SET school_name = ? WHERE school_name = ?")->execute([$schoolName, $oldSchoolName]);
            $pdo->prepare("UPDATE principals SET school_name = ? WHERE school_name = ?")->execute([$schoolName, $oldSchoolName]);
            $pdo->prepare("UPDATE dean_of_studies SET school_name = ? WHERE school_name = ?")->execute([$schoolName, $oldSchoolName]);
        }

        respond(true, "School '$schoolName' updated successfully.", [
            'id' => $schoolId,
            'name' => $schoolName,
            'region' => $region,
            'division' => $division,
            'town' => $town
        ]);
        break;

    // ── 11. DELETE SCHOOL ───────────────────────────────────────
    case 'delete_school':
        $schoolId   = intval($body['id'] ?? $body['school_id'] ?? $_GET['id'] ?? 0);
        $schoolName = trim($body['name'] ?? $body['school_name'] ?? $_GET['school_name'] ?? '');

        if ($schoolId <= 0 && !empty($schoolName)) {
            $stmtFind = $pdo->prepare("SELECT id FROM schools WHERE LOWER(name) = LOWER(?)");
            $stmtFind->execute([$schoolName]);
            $schoolId = intval($stmtFind->fetchColumn());
        }

        if ($schoolId <= 0) {
            respondError('School ID or School Name is required.');
        }

        $stmt = $pdo->prepare("DELETE FROM schools WHERE id = ?");
        $stmt->execute([$schoolId]);

        respond(true, "School deleted successfully from directory.", ['deleted_id' => $schoolId]);
        break;

    // ── 12. TOGGLE SCHOOL STATUS (BLOCK / UNBLOCK) ──────────────
    case 'toggle_school_status':
        $schoolId  = intval($body['id'] ?? $body['school_id'] ?? $_GET['id'] ?? 0);
        $statusVal = intval($body['is_active'] ?? $_GET['is_active'] ?? 1);
        $schoolName= trim($body['name'] ?? $body['school_name'] ?? '');

        if ($schoolId <= 0 && !empty($schoolName)) {
            $stmtFind = $pdo->prepare("SELECT id FROM schools WHERE LOWER(name) = LOWER(?)");
            $stmtFind->execute([$schoolName]);
            $schoolId = intval($stmtFind->fetchColumn());
        }

        if ($schoolId <= 0) respondError('School ID is required.');

        $stmt = $pdo->prepare("UPDATE schools SET is_active = ? WHERE id = ?");
        $stmt->execute([$statusVal, $schoolId]);

        $statusMsg = $statusVal === 1 ? 'activated/unblocked' : 'blocked/suspended';
        respond(true, "School status updated to $statusMsg.", ['id' => $schoolId, 'is_active' => $statusVal]);
        break;
"""

# Insert school_crud_cases right before default:
if "case 'add_school':" not in code:
    code = code.replace("    default:\n        respondError(\"Unknown action '$action'.\");", school_crud_cases + "\n    default:\n        respondError(\"Unknown action '$action'.\");")

with open(r'backend/api/admin.php', 'w', encoding='utf-8') as f:
    f.write(code)

shutil.copy2(r'backend/api/admin.php', r'd:/xammp/htdocs/minesec_api/api/admin.php')
print("SUCCESS: ADMIN.PHP UPDATED WITH SCHOOL CRUD ACTIONS")
