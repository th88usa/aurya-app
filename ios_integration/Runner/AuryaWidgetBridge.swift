import Flutter
import WidgetKit
import UIKit

// Register once with the generated Flutter engine's binaryMessenger (see IOS_WIDGET.md).
final class AuryaWidgetBridge {
    private static var channel: FlutterMethodChannel?
    private static var timeObserver: NSObjectProtocol?
    static func register(with messenger: FlutterBinaryMessenger) {
        let bridge = FlutterMethodChannel(name: "aurya/widget", binaryMessenger: messenger)
        bridge.setMethodCallHandler { call, result in
            do {
                switch call.method {
                case "save":
                    guard let json = call.arguments as? String, let data = json.data(using: .utf8)
                    else { throw AuryaWidgetError.invalidPayload }
                    try AuryaWidgetStore.save(data)
                case "clear": try AuryaWidgetStore.clear()
                default: result(FlutterMethodNotImplemented); return
                }
                // Request only after a configuration change; never a polling loop.
                WidgetCenter.shared.reloadTimelines(ofKind: AuryaWidgetStore.kind)
                result(nil)
            } catch {
                result(FlutterError(code: "WIDGET_CONFIG", message: "Configuração/App Group indisponível.", details: nil))
            }
        }
        channel = bridge
        if let observer = timeObserver { NotificationCenter.default.removeObserver(observer) }
        // Only works while the containing process can receive this event; device testing is required.
        timeObserver = NotificationCenter.default.addObserver(forName: UIApplication.significantTimeChangeNotification,
            object: nil, queue: .main) { _ in
                WidgetCenter.shared.reloadTimelines(ofKind: AuryaWidgetStore.kind)
            }
    }
}
