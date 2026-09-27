"""Parse and elaborate each lab independently; this does not simulate hardware."""
from pathlib import Path
import os,sys
from pyslang.driver import Driver
from pyslang import DiagnosticEngine

root=Path(__file__).resolve().parents[1]
os.chdir(root)
failed=False
groups=sorted(list((root/'riscv-cpu-cache').iterdir())+list((root/'digital-systems').iterdir()))
for group in groups:
    files=list(group.glob('*.v'))
    if not files:continue
    driver=Driver();driver.addStandardArgs();driver.setTerminalColorsEnabled(False)
    args='--single-unit '+' '.join('"'+p.relative_to(root).as_posix()+'"' for p in files)
    parsed=driver.parseCommandLine(args) and driver.processOptions() and driver.parseAllSources()
    compilation=driver.createCompilation()
    diags=compilation.getAllDiagnostics()
    errors=sum(d.isError() for d in diags)
    print(f'{group.name}: {errors} errors, {len(diags)-errors} warnings')
    if diags:print(DiagnosticEngine.reportAll(driver.sourceManager,diags))
    failed|=not parsed or errors>0
sys.exit(1 if failed else 0)
