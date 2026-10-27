import os, pathlib, socket, subprocess, tempfile, unittest, threading
from http.server import BaseHTTPRequestHandler, HTTPServer

ROOT = pathlib.Path(__file__).parent / 'scripts' / 'linux'

def run(name, *args, env=None):
    return subprocess.run(['/bin/bash', str(ROOT / name), *args], env=env,
                          capture_output=True, text=True, timeout=15)

def fake(path, text):
    path.write_text('#!/bin/bash\n' + text + '\n')
    path.chmod(0o755)

class Checks(unittest.TestCase):
    def test_storage_mock_df(self):
        with tempfile.TemporaryDirectory() as d:
            fake(pathlib.Path(d) / 'df', '''
if [[ "$1" == "-Pi" ]]; then
  printf 'Filesystem Inodes IUsed IFree IUse%% Mounted on\\n/dev/sda1 1000 70 930 7%% /mount with spaces\\n'
else
  printf 'Filesystem Blocks Used Available Capacity Mounted on\\n/dev/sda1 1000 400 600 40%% /mount with spaces\\n'
fi''')
            e = dict(os.environ, PATH=d + ':/usr/bin:/bin')
            self.assertEqual(run('check-storage.sh','/','80',env=e).returncode, 0)
            self.assertEqual(run('check-storage.sh','/','30',env=e).returncode, 1)
            fake(pathlib.Path(d) / 'df', "printf 'Filesystem Blocks Used Available Capacity Mounted on\\n/dev/sda1 1000 0 1000 - /mount with spaces\\n'")
            self.assertEqual(run('check-storage.sh','/',env=e).returncode, 2)
            self.assertEqual(run('check-storage.sh','/','101',env=e).returncode, 2)
            self.assertEqual(run('check-storage.sh','/does-not-exist',env=e).returncode, 2)

    def test_services_states_and_precedence(self):
        with tempfile.TemporaryDirectory() as d:
            fake(pathlib.Path(d) / 'systemctl', '''
case "$1" in
  show) case "$2" in
    --property=Version) echo 252;;
    active.service) printf 'LoadState=loaded\\nActiveState=active\\nSubState=running\\n';;
    stopped.service) printf 'LoadState=loaded\\nActiveState=inactive\\nSubState=dead\\n';;
    failed.service) printf 'LoadState=loaded\\nActiveState=failed\\nSubState=failed\\n';;
    missing.service) printf 'LoadState=not-found\\nActiveState=inactive\\nSubState=dead\\n';;
    *) exit 1;;
  esac;;
esac''')
            e = dict(os.environ, PATH=d + ':/usr/bin:/bin')
            for args, expected in [(('active.service',),0), (('stopped.service',),1),
                 (('failed.service',),1), (('missing.service',),3),
                 (('stopped.service','missing.service'),3),
                 (('missing.service','badname'),2)]:
                self.assertEqual(run('check-services.sh',*args,env=e).returncode, expected)

    def test_inventory_partial_and_creation_error(self):
        with tempfile.TemporaryDirectory() as d:
            bindir = pathlib.Path(d) / 'bin'; bindir.mkdir()
            for name in ('date','cat','uname','hostnamectl','uptime','free','lsblk','df','ip','timedatectl','systemctl','mktemp'):
                target = subprocess.run(['bash','-c','command -v "$1"','_',name], capture_output=True,text=True).stdout.strip()
                if target: (bindir/name).symlink_to(target)
            e = dict(os.environ, PATH=str(bindir), HOME=d)
            result = run('collect-system-info.sh',env=e)
            self.assertEqual(result.returncode,3)
            self.assertIn('Não disponível: lscpu',result.stdout)
            self.assertEqual(run('collect-system-info.sh','--bad',env=e).returncode,2)
            self.assertEqual(run('collect-system-info.sh','--report',env=e).returncode,1)

    def test_network_local_and_http_failures(self):
        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                self.send_response(500 if self.path == '/error' else 200)
                self.end_headers()
            def log_message(self, *args): pass
        server = HTTPServer(('127.0.0.1',0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True); thread.start()
        try:
            with tempfile.TemporaryDirectory() as d:
                fake(pathlib.Path(d) / 'ip', 'echo "default via 192.0.2.1 dev eth0"')
                e = dict(os.environ,PATH=d + ':/usr/bin:/bin')
                port=str(server.server_port); url=f'http://127.0.0.1:{port}'
                self.assertEqual(run('check-network.sh','localhost',port,url,env=e).returncode,0)
                self.assertEqual(run('check-network.sh','localhost',port,url+'/error',env=e).returncode,1)
                self.assertEqual(run('check-network.sh','localhost','0',url,env=e).returncode,2)
                self.assertEqual(run('check-network.sh','localhost',port,'http://user:pass@localhost',env=e).returncode,2)
                self.assertEqual(run('check-network.sh','nonexistent.invalid',port,url,'1',env=e).returncode,1)
                with socket.socket() as closed:
                    closed.bind(('127.0.0.1', 0))
                    closed_port = str(closed.getsockname()[1])
                    result = run('check-network.sh','localhost',closed_port,url,'1',env=e)
                    self.assertEqual(result.returncode,1)
                    self.assertIn('TCP: falhou', result.stdout)
        finally:
            server.shutdown(); thread.join(); server.server_close()

if __name__ == '__main__': unittest.main(verbosity=2)
