import sqlite3
import re

input_file = 'motobime_betebrana.sql'
output_file = 'motobime_betebrana_d1.sql'

with open(input_file, 'r', encoding='utf-8') as f:
    sql = f.read()

# 1. Remove MySQL specific SET commands
sql = re.sub(r'^SET .*?;$', '', sql, flags=re.MULTILINE)
sql = re.sub(r'^START TRANSACTION;$', '', sql, flags=re.MULTILINE)
sql = re.sub(r'^COMMIT;$', '', sql, flags=re.MULTILINE)
sql = re.sub(r'^/\*!.*?\*/;$', '', sql, flags=re.MULTILINE)

# 2. Convert AUTO_INCREMENT to AUTOINCREMENT
sql = re.sub(r'\bAUTO_INCREMENT\b', 'AUTOINCREMENT', sql, flags=re.IGNORECASE)

# 3. Remove ENGINE=InnoDB DEFAULT CHARSET=...
sql = re.sub(r'\) ENGINE=.*?;', ');', sql, flags=re.IGNORECASE)

# 4. SQLite integer types don't take length like int(11) -> INTEGER
sql = re.sub(r'\bint\(\d+\)', 'INTEGER', sql, flags=re.IGNORECASE)
sql = re.sub(r'\btinyint\(\d+\)', 'INTEGER', sql, flags=re.IGNORECASE)

# 5. D1 requires INTEGER PRIMARY KEY AUTOINCREMENT
sql = re.sub(r'INTEGER\s+NOT\s+NULL\s+AUTOINCREMENT', 'INTEGER PRIMARY KEY AUTOINCREMENT', sql, flags=re.IGNORECASE)

# 6. Remove standalone PRIMARY KEY (...) constraints if we already set AUTOINCREMENT inline
def fix_pk(match):
    table_body = match.group(0)
    if 'INTEGER PRIMARY KEY AUTOINCREMENT' in table_body:
        table_body = re.sub(r',\s*PRIMARY KEY \([^)]+\)', '', table_body, flags=re.IGNORECASE)
    return table_body

sql = re.sub(r'CREATE TABLE.*?\(.*?\);', fix_pk, sql, flags=re.IGNORECASE | re.DOTALL)

# 7. Fix current_timestamp() and ON UPDATE CURRENT_TIMESTAMP
sql = re.sub(r'\bcurrent_timestamp\(\)', 'CURRENT_TIMESTAMP', sql, flags=re.IGNORECASE)
sql = re.sub(r'\bON UPDATE CURRENT_TIMESTAMP\b', '', sql, flags=re.IGNORECASE)

# 8. SQLite does not support ENUM, convert to TEXT
sql = re.sub(r'\benum\([^)]+\)', 'TEXT', sql, flags=re.IGNORECASE)

# 9. SQLite escapes single quotes with two single quotes ('') instead of backslash (\')
sql = sql.replace("\\'", "''")

# 10. Remove ALTER TABLE blocks (SQLite doesn't support ALTER TABLE ADD PRIMARY KEY, etc.)
sql = re.sub(r'ALTER TABLE.*?;', '', sql, flags=re.IGNORECASE | re.DOTALL)

with open(output_file, 'w', encoding='utf-8') as f:
    f.write(sql)

# Validate
statements = sql.split(';')
conn = sqlite3.connect(':memory:')
success = True
for i, stmt in enumerate(statements):
    stmt = stmt.strip()
    if not stmt:
        continue
    try:
        conn.execute(stmt)
    except sqlite3.Error as e:
        print(f'Error in statement {i}:\n{stmt}\nError: {e}')
        success = False
        break

if success:
    print('Conversion and Validation to D1 complete. Saved as', output_file)
