"""Prepare a separate Swift package for Widget timeline and payload checks on macOS."""
from pathlib import Path
import shutil
root = Path(__file__).resolve().parent.parent
package = root / '.codemagic-widget-tests'
package.mkdir(exist_ok=False)
sources = package / 'Sources' / 'AuryaWidgetCore'
tests = package / 'Tests' / 'AuryaWidgetCoreTests'
sources.mkdir(parents=True)
tests.mkdir(parents=True)
(package / 'Package.swift').write_text('// swift-tools-version: 5.9\nimport PackageDescription\nlet package = Package(name: "AuryaWidgetCore", platforms: [.macOS(.v13)],\n    products: [.library(name: "AuryaWidgetCore", targets: ["AuryaWidgetCore"])],\n    targets: [.target(name: "AuryaWidgetCore"),\n              .testTarget(name: "AuryaWidgetCoreTests", dependencies: ["AuryaWidgetCore"])])\n', encoding='utf-8')
for name in ('AuryaWidgetStore.swift', 'AuryaTimelineEngine.swift'):
    shutil.copy2(root / 'ios_integration' / 'Shared' / name, sources / name)
text = (root / 'ios_integration/Tests/AuryaTimelineTests.swift').read_text(encoding='utf-8')
(tests / 'AuryaTimelineTests.swift').write_text('@testable import AuryaWidgetCore\n' + text, encoding='utf-8')
print('Prepared pure widget timeline/payload tests; does not register an App Group or install an extension.')
