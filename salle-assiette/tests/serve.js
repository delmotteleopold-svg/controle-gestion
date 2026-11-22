// Mini-serveur de test (s'arrête avec le script)
const http=require('http'), fs=require('fs'), path=require('path');
const T={'.html':'text/html; charset=utf-8','.js':'text/javascript','.json':'application/json','.png':'image/png','.svg':'image/svg+xml'};
module.exports=(root,port)=>new Promise(r=>{ const s=http.createServer((q,res)=>{ let f=path.join(root,decodeURIComponent(q.url.split('?')[0])); if(f.endsWith('/')) f+='index.html';
  fs.readFile(f,(e,d)=>{ if(e){ res.writeHead(404); return res.end('404'); } res.writeHead(200,{'Content-Type':T[path.extname(f)]||'application/octet-stream'}); res.end(d); }); }); s.listen(port,()=>r(s)); });
