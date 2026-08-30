import shutil

with open(r'backend/api/dashboard.php', 'r', encoding='utf-8') as f:
    text = f.read()

old_query = """        $stmtVark = $pdo->query("
            SELECT 
                COUNT(DISTINCT a.student_id) AS assessed,
                SUM(CASE WHEN a.learning_style LIKE '%Visual%' THEN 1 ELSE 0 END) AS visual,
                SUM(CASE WHEN a.learning_style LIKE '%Auditory%' THEN 1 ELSE 0 END) AS auditory,
                SUM(CASE WHEN a.learning_style LIKE '%Kinesthetic%' THEN 1 ELSE 0 END) AS kinesthetic,
                SUM(CASE WHEN a.learning_style LIKE '%Read%' THEN 1 ELSE 0 END) AS rw_count
            FROM assessments a
        ");"""

new_query = """        $stmtVark = $pdo->query("
            SELECT 
                COUNT(DISTINCT st.id) AS assessed,
                COALESCE(SUM(CASE WHEN latest_a.learning_style LIKE '%Visual%' THEN 1 ELSE 0 END), 0) AS visual,
                COALESCE(SUM(CASE WHEN latest_a.learning_style LIKE '%Auditory%' THEN 1 ELSE 0 END), 0) AS auditory,
                COALESCE(SUM(CASE WHEN latest_a.learning_style LIKE '%Kinesthetic%' THEN 1 ELSE 0 END), 0) AS kinesthetic,
                COALESCE(SUM(CASE WHEN latest_a.learning_style LIKE '%Read%' THEN 1 ELSE 0 END), 0) AS rw_count
            FROM students st
            JOIN (
                SELECT a1.student_id, a1.learning_style
                FROM assessments a1
                INNER JOIN (
                    SELECT student_id, MAX(id) as max_id
                    FROM assessments
                    GROUP BY student_id
                ) a2 ON a1.id = a2.max_id
            ) latest_a ON latest_a.student_id = st.id
        ");"""

text = text.replace(old_query, new_query)

with open(r'backend/api/dashboard.php', 'w', encoding='utf-8') as f:
    f.write(text)

try:
    shutil.copy2(r'backend/api/dashboard.php', r'd:/xammp/htdocs/minesec_api/api/dashboard.php')
    print('SUCCESSFULLY COPIED dashboard.php TO XAMPP')
except Exception as e:
    print('XAMPP copy note:', e)
