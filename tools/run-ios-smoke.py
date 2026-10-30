"""Run the reviewed Flutter integration test on a disposable CI simulator."""
from pathlib import Path
import json
import subprocess

root = Path(__file__).resolve().parent.parent
project = root / '.codemagic-ios'
def command(args, timeout=180, capture=False):
    return subprocess.run(args, cwd=project, text=True, check=True,
                          timeout=timeout, capture_output=capture)

inventory = json.loads(command(['xcrun', 'simctl', 'list', 'devices', 'available', '-j'], capture=True).stdout)
candidates = [device for runtime, devices in inventory['devices'].items() if '.iOS-' in runtime
              for device in devices if device.get('isAvailable') and device['name'].startswith('iPhone')]
if not candidates:
    raise SystemExit('No available iPhone simulator runtime. No device test was performed.')
device = candidates[0]
identifier = device['udid']
print('Using iPhone simulator:', device['name'], flush=True)
if device['state'] != 'Booted':
    command(['xcrun', 'simctl', 'boot', identifier])
try:
    command(['xcrun', 'simctl', 'bootstatus', identifier, '-b'], timeout=180)
    command(['flutter', 'drive', '--driver=test_driver/native_driver.dart',
             '--target=integration_test/native_smoke_test.dart', '-d', identifier], timeout=900)
finally:
    command(['xcrun', 'simctl', 'shutdown', identifier])
