// Piratech — auto-correcteur avant déploiement (statique “Other”)
const fs = require('fs');
const path = require('path');
const mustHave = [
  'index.html','styles.css','app.js','i18n.js','db.js',
  'manifest.webmanifest','service-worker.js','icon-192.png','icon-512.png',
  'robots.txt','vercel.json','README.md'
];
function ensureFile(p, placeholder=''){ if(!fs.existsSync(p)){ fs.writeFileSync(p, placeholder || `<!-- placeholder ${p} -->`); console.warn(`Création placeholder pour ${p}`); } }
function removeIfExists(p){ if(fs.existsSync(p)){ const s=fs.statSync(p); if(s.isDirectory()) fs.rmSync(p,{recursive:true,force:true}); else fs.unlinkSync(p); console.warn(`Suppression auto de ${p} (statique)`);} }
mustHave.forEach(f=>ensureFile(f));
['middleware.ts','middleware.js','api','pages/api'].forEach(removeIfExists);
if(!fs.existsSync('vercel.json')){
  fs.writeFileSync('vercel.json', JSON.stringify({
    headers: [{ source: "/(.*)", headers: [
      { "key": "X-Robots-Tag", "value": "noindex, nofollow" },
      { "key": "Referrer-Policy", "value": "same-origin" },
      { "key": "X-Content-Type-Options", "value": "nosniff" },
      { "key": "Permissions-Policy", "value": "geolocation=(), microphone=(), camera=()" },
      { "key": "Content-Security-Policy", "value": "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self'; connect-src 'self';" }
    ]}]
  }, null, 2));
}
console.log('✅ Piratech: vérifications et corrections effectuées.');
