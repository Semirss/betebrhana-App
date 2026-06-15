require('dotenv').config();
const axios = require('axios');

async function executeD1(query) {
    const accountId = process.env.CF_ACCOUNT_ID;
    const dbId = process.env.CF_D1_DATABASE_ID;
    const token = process.env.CF_API_TOKEN;

    const url = `https://api.cloudflare.com/client/v4/accounts/${accountId}/d1/database/${dbId}/query`;
    
    const response = await axios.post(url, {
      sql: query
    }, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });

    return response.data.result[0];
}

async function check() {
    try {
        const result = await executeD1("SELECT name, sql FROM sqlite_master WHERE type='table';");
        console.log(JSON.stringify(result.results, null, 2));
    } catch (e) {
        console.error(e.response ? e.response.data : e.message);
    }
}

check();
