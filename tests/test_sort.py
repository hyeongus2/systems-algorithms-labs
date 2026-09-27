"""Run the compiled insertion-sort program against CLI and sorting edge cases."""
from pathlib import Path
import argparse,random,subprocess

def check(executable):
    rng=random.Random(2026)
    cases=[[],[0],[-2147483648,2147483647,0], [3,3,-1,2],list(range(10)),list(range(9,-1,-1))]
    cases += [[rng.randint(-100000,100000) for _ in range(rng.randrange(11))] for _ in range(100)]
    for values in cases:
        r=subprocess.run([str(executable),*map(str,values)],capture_output=True,text=True,timeout=3)
        assert r.returncode==0,(values,r.stderr)
        assert [int(v) for v in r.stdout.split()]==sorted(values),(values,r.stdout)
    for args in [['1']*11,['abc'],['1x'],['2147483648'],['-2147483649'],['']]:
        r=subprocess.run([str(executable),*args],capture_output=True,text=True,timeout=3)
        assert r.returncode!=0 and r.stderr,args
    print(f'{len(cases)+6} CLI cases passed')

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('executable',type=Path)
    check(ap.parse_args().executable.resolve())
