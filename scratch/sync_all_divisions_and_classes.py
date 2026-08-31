import re

# 1. Update backend/api/admin.php
with open('backend/api/admin.php', 'r', encoding='utf-8') as f:
    admin_php = f.read()

# Fix 1: Remove hardcoded classes count overwrite
admin_php = admin_php.replace(
    "if ($classesCount == 0) $classesCount = 2;",
    "// $classesCount stays 0 if no classes enrolled yet"
)

# Fix 2: Auto-insert missing division in create_school & add_school
auto_div_snippet = """        // Auto-register division into divisions table if missing
        $stmtRegId = $pdo->prepare("SELECT id FROM regions WHERE UPPER(name_fr) = UPPER(?) OR UPPER(name_en) = UPPER(?) OR UPPER(code) = UPPER(?) LIMIT 1");
        $stmtRegId->execute([$region, $region, $region]);
        $regId = $stmtRegId->fetchColumn();
        if ($regId && !empty($division)) {
            $stmtChkDiv = $pdo->prepare("SELECT id FROM divisions WHERE region_id = ? AND (UPPER(code) = UPPER(?) OR UPPER(name_en) = UPPER(?) OR UPPER(name_fr) = UPPER(?))");
            $stmtChkDiv->execute([$regId, $division, $division, $division]);
            if (!$stmtChkDiv->fetch()) {
                $divCode = strtoupper(preg_replace('/[^a-zA-Z0-9]/', '_', $division));
                $pdo->prepare("INSERT INTO divisions (region_id, code, name_en, name_fr, created_at) VALUES (?, ?, ?, ?, NOW())")
                    ->execute([$regId, $divCode, ucfirst(strtolower($division)), ucfirst(strtolower($division))]);
            }
        }
"""

old_create_school = """        $stmt = $pdo->prepare("INSERT INTO schools (name, region, division, town) VALUES (?, ?, ?, ?)");
        $stmt->execute([$name, $region, $division, $town]);
        $newSchoolId = $pdo->lastInsertId();"""

new_create_school = auto_div_snippet + """        $stmt = $pdo->prepare("INSERT INTO schools (name, region, division, town) VALUES (?, ?, ?, ?)");
        $stmt->execute([$name, $region, $division, $town]);
        $newSchoolId = $pdo->lastInsertId();"""

if old_create_school in admin_php:
    admin_php = admin_php.replace(old_create_school, new_create_school)
    print("SUCCESS: Added auto-division registration in create_school")
else:
    print("WARNING: old_create_school not matched exact")

old_add_school = """        $stmt = $pdo->prepare("INSERT INTO schools (code, name, region, division, town, is_active, created_at) VALUES (?, ?, ?, ?, ?, 1, NOW())");
        $stmt->execute([$code, $schoolName, $region, $division, $town]);
        $newId = $pdo->lastInsertId();"""

new_add_school = auto_div_snippet.replace('$region', '$region').replace('$division', '$division') + """        $stmt = $pdo->prepare("INSERT INTO schools (code, name, region, division, town, is_active, created_at) VALUES (?, ?, ?, ?, ?, 1, NOW())");
        $stmt->execute([$code, $schoolName, $region, $division, $town]);
        $newId = $pdo->lastInsertId();"""

if old_add_school in admin_php:
    admin_php = admin_php.replace(old_add_school, new_add_school)
    print("SUCCESS: Added auto-division registration in add_school")
else:
    print("WARNING: old_add_school not matched exact")

with open('backend/api/admin.php', 'w', encoding='utf-8') as f:
    f.write(admin_php)

# 2. Update backend/api/dashboard.php
with open('backend/api/dashboard.php', 'r', encoding='utf-8') as f:
    dash_php = f.read()

old_dash_hierarchy = """        // Build full national hierarchy for all 10 Regions: Region -> Division -> School -> Class
        $nationalItems = [];
        foreach ($allCameroonRegions as $regName) {
            $stmtDivs = $pdo->prepare("SELECT DISTINCT division FROM schools WHERE region = ? AND division IS NOT NULL AND division != '' ORDER BY division");
            $stmtDivs->execute([$regName]);
            $divList = $stmtDivs->fetchAll(PDO::FETCH_COLUMN);

            $divItems = [];
            foreach ($divList as $divName) {
                $stmtSc = $pdo->prepare("SELECT id, name FROM schools WHERE region = ? AND division = ? ORDER BY name");
                $stmtSc->execute([$regName, $divName]);
                $schoolsList = $stmtSc->fetchAll(PDO::FETCH_ASSOC);"""

new_dash_hierarchy = """        // Build full national hierarchy for all 10 Regions: Region -> Division -> School -> Class
        $nationalItems = [];
        foreach ($allCameroonRegions as $regName) {
            $stmtDivs = $pdo->prepare("
                SELECT DISTINCT division_name FROM (
                    SELECT UPPER(d.code) AS division_name FROM divisions d JOIN regions r ON r.id = d.region_id 
                    WHERE UPPER(r.name_fr) = UPPER(?) OR UPPER(r.name_en) = UPPER(?) OR UPPER(r.code) = UPPER(?) OR UPPER(r.name_fr) = UPPER(REPLACE(?, '-', ' '))
                    UNION
                    SELECT UPPER(division) AS division_name FROM schools 
                    WHERE (UPPER(region) = UPPER(?) OR UPPER(region) = UPPER(REPLACE(?, '-', ' '))) AND division IS NOT NULL AND division != ''
                ) AS combined_divs
                WHERE division_name IS NOT NULL AND division_name != ''
                ORDER BY division_name
            ");
            $stmtDivs->execute([$regName, $regName, $regName, $regName, $regName, $regName]);
            $divList = $stmtDivs->fetchAll(PDO::FETCH_COLUMN);

            $divItems = [];
            foreach ($divList as $divName) {
                $stmtSc = $pdo->prepare("SELECT id, name FROM schools WHERE (UPPER(region) = UPPER(?) OR UPPER(region) = UPPER(REPLACE(?, '-', ' '))) AND (UPPER(division) = UPPER(?) OR UPPER(division) = UPPER(REPLACE(?, '_', '-'))) ORDER BY name");
                $stmtSc->execute([$regName, $regName, $divName, $divName]);
                $schoolsList = $stmtSc->fetchAll(PDO::FETCH_ASSOC);"""

if old_dash_hierarchy in dash_php:
    dash_php = dash_php.replace(old_dash_hierarchy, new_dash_hierarchy)
    print("SUCCESS: Updated national hierarchy builder in backend/api/dashboard.php")
else:
    print("WARNING: old_dash_hierarchy not matched exact")

with open('backend/api/dashboard.php', 'w', encoding='utf-8') as f:
    f.write(dash_php)

# 3. Update lib/views/dashboards/admin_dashboard.dart
with open('lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    admin_dart = f.read()

# In _fetchAllUsersAndSchools, also trigger _fetchDashboardData to reload the sidebar tree!
old_fetch_all = """  Future<void> _fetchAllUsersAndSchools() async {
    setState(() => _isLoadingUsers = true);
    try {
      final uResp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin.php?action=get_all_users'),
      );
      final uData = jsonDecode(uResp.body);

      final sResp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin.php?action=get_all_schools'),
      );
      final sData = jsonDecode(sResp.body);

      setState(() {
        if (uData['success'] == true && uData['data'] != null) {
          _allUsersList = uData['data'] as List;
        }
        if (sData['success'] == true && sData['data'] != null) {
          _allSchoolsList = sData['data'] as List;
        }
        _isLoadingUsers = false;
      });
    } catch (_) {
      setState(() => _isLoadingUsers = false);
    }
  }"""

new_fetch_all = """  Future<void> _fetchAllUsersAndSchools() async {
    setState(() => _isLoadingUsers = true);
    try {
      final uResp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin.php?action=get_all_users'),
      );
      final uData = jsonDecode(uResp.body);

      final sResp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin.php?action=get_all_schools'),
      );
      final sData = jsonDecode(sResp.body);

      setState(() {
        if (uData['success'] == true && uData['data'] != null) {
          _allUsersList = uData['data'] as List;
        }
        if (sData['success'] == true && sData['data'] != null) {
          _allSchoolsList = sData['data'] as List;
        }
        _isLoadingUsers = false;
      });
      _fetchDashboardData(); // Refresh sidebar regional hierarchy dynamically
    } catch (_) {
      setState(() => _isLoadingUsers = false);
    }
  }"""

if old_fetch_all in admin_dart:
    admin_dart = admin_dart.replace(old_fetch_all, new_fetch_all)
    print("SUCCESS: Updated _fetchAllUsersAndSchools to reload sidebar hierarchy")
else:
    print("WARNING: old_fetch_all not matched exact")

with open('lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(admin_dart)

print("ALL SYNCED!")
