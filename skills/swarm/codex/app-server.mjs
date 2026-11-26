import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import { EventEmitter } from 'node:events';

export class AppServer extends EventEmitter {
  #nextId = 0;
  #pending = new Map();
  #closed;

  constructor(cwd) {
    super();
    this.child = spawn(process.env.SWARM_CODEX_BIN || 'codex', ['--disable', 'multi_agent', '--disable', 'multi_agent_v2', 'app-server'], {
      cwd,
      stdio: ['pipe', 'pipe', 'inherit'],
    });
    createInterface({ input: this.child.stdout }).on('line', line => this.#receive(line));
    this.child.stdin.on('error', error => this.#fail(error));
    this.child.on('error', error => this.#fail(error));
    this.child.on('exit', (code, signal) => this.#fail(new Error('Codex App Server exited (' + (signal ?? code) + ')')));
  }

  #fail(error) {
    if (this.#closed) return;
    this.#closed = error;
    for (const { reject } of this.#pending.values()) reject(error);
    this.#pending.clear();
    this.emit('closed', error);
  }

  #receive(line) {
    let message;
    try { message = JSON.parse(line); } catch { return; }
    if (message.method) {
      if (message.id === undefined) {
        this.emit('notification', message.method, message.params ?? {});
      } else {
        // Unattended turns cannot satisfy interactive requests.
        this.#send({ id: message.id, error: { code: -32601, message: 'Interactive requests are unavailable in Swarm Board.' } });
      }
      return;
    }
    const pending = this.#pending.get(message.id);
    if (!pending) return;
    this.#pending.delete(message.id);
    if (message.error) pending.reject(new Error(message.error.message));
    else pending.resolve(message.result);
  }

  #send(message) {
    this.child.stdin.write(JSON.stringify(message) + '\n');
  }

  request(method, params) {
    if (this.#closed) return Promise.reject(this.#closed);
    const id = ++this.#nextId;
    return new Promise((resolve, reject) => {
      this.#pending.set(id, { resolve, reject });
      this.#send({ id, method, params });
    });
  }

  async initialize() {
    await this.request('initialize', {
      clientInfo: { name: 'codex-swarm-board', version: '0.1.0' },
      capabilities: { experimentalApi: false },
    });
    this.#send({ method: 'initialized' });
  }

  close() {
    this.child.kill();
  }
}
