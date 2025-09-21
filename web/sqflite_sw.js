// sqflite web worker
importScripts('https://cdn.jsdelivr.net/npm/sql.js@1.8.0/dist/sql-wasm.js');

let db;

self.addEventListener('message', async (event) => {
  const { id, method, args } = event.data;
  
  try {
    let result;
    
    switch (method) {
      case 'init':
        const SQL = await initSqlJs({
          locateFile: file => `https://cdn.jsdelivr.net/npm/sql.js@1.8.0/dist/${file}`
        });
        db = new SQL.Database();
        result = { success: true };
        break;
        
      case 'execute':
        if (!db) throw new Error('Database not initialized');
        const stmt = db.prepare(args.sql);
        if (args.parameters) {
          stmt.bind(args.parameters);
        }
        const rows = [];
        while (stmt.step()) {
          rows.push(stmt.getAsObject());
        }
        stmt.free();
        result = rows;
        break;
        
      case 'close':
        if (db) {
          db.close();
          db = null;
        }
        result = { success: true };
        break;
        
      default:
        throw new Error(`Unknown method: ${method}`);
    }
    
    self.postMessage({ id, result });
  } catch (error) {
    self.postMessage({ id, error: error.message });
  }
});