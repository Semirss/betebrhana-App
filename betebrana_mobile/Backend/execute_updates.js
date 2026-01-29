const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function run() {
    const pool = mysql.createPool({
        host: process.env.MYSQL_HOST || "localhost",
        user: process.env.MYSQL_USER || "root",
        password: process.env.MYSQL_PASSWORD || "",
        database: process.env.MYSQL_DATABASE || "betebrana",
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0,
    });

    try {
        const schemaPath = path.join(__dirname, 'admin_schema_updates_v3.sql');
        const schemaSql = fs.readFileSync(schemaPath, 'utf8');
        const statements = schemaSql.split(';').filter(stmt => stmt.trim());

        for (const statement of statements) {
            try {
                await pool.execute(statement);
                console.log("Executed: " + statement.substring(0, 50) + "...");
            } catch (e) {
                console.log("Error (might already exist): " + e.message);
            }
        }
        console.log("Done.");
    } catch (e) {
        console.error(e);
    } finally {
        await pool.end();
        process.exit();
    }
}

run();
