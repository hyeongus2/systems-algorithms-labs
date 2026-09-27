"""POSIX runtime checks for the compiled mini shell; run on Linux/macOS."""
from pathlib import Path
import argparse,subprocess

def run(executable,commands):
    return subprocess.run([str(executable)],input=commands,capture_output=True,text=True,timeout=5)

def check(executable):
    assert run(executable,'').returncode==0
    assert run(executable,'\n\t\nexit\n').returncode==0
    r=run(executable,'printf hello')
    assert r.returncode==0 and r.stdout=='hello'
    r=run(executable,'printf\thello\nexit\n')
    assert r.returncode==0 and r.stdout=='hello'
    r=run(executable,'no_such_portfolio_command_2026\nprintf ok\n')
    assert r.stdout=='ok' and r.stderr
    r=run(executable,'printf '+'x '*65+'\nprintf ok\n')
    assert r.stdout=='ok' and 'too many arguments' in r.stderr
    r=run(executable,'x'*2200+'\nprintf ok\n')
    assert r.stdout=='ok' and 'line too long' in r.stderr
    print('7 POSIX shell cases passed')

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('executable',type=Path)
    check(ap.parse_args().executable.resolve())
