<?php
$mysqli = new mysqli('127.0.0.1', 'root', '', 'minesec_lst');
if ($mysqli->connect_error) {
    die("Connection failed: " . $mysqli->connect_error);
}

// Update students table where full_name is NULL or empty
$res = $mysqli->query("
    UPDATE students st
    JOIN users u ON u.id = st.user_id
    SET st.full_name = u.full_name
    WHERE st.full_name IS NULL OR st.full_name = ''
");

echo "Updated " . $mysqli->affected_rows . " student names in database.\n";
