const fs = require('fs');
const path = require('path');

// Read the API_URL environment variable from Vercel (fallback to the Render url if not provided)
const apiUrl = process.env.API_URL || "https://betebrhana-app.onrender.com/api";

const apiFilePath = path.join(__dirname, 'js', 'api.js');

try {
  if (fs.existsSync(apiFilePath)) {
    let content = fs.readFileSync(apiFilePath, 'utf8');
    
    // Replace the line: const API_URL = "...";
    const updatedContent = content.replace(/const API_URL\s*=\s*["'][^"']*["'];/, `const API_URL = "${apiUrl}";`);
    
    fs.writeFileSync(apiFilePath, updatedContent, 'utf8');
    console.log(`[Build] Successfully updated API_URL in js/api.js to: ${apiUrl}`);
  } else {
    console.error(`[Error] js/api.js file not found at: ${apiFilePath}`);
    process.exit(1);
  }
} catch (error) {
  console.error('[Error] Failed to update API_URL during build:', error);
  process.exit(1);
}
