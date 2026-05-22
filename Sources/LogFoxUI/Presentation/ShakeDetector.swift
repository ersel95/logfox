#if canImport(UIKit)
import UIKit

public extension Notification.Name {
    /// Cihaz sallandığında gönderilir. `LogFoxPresenter` bunu dinler.
    static let logFoxShake = Notification.Name("com.logfox.shake")
}

/// Sallama algılama, `UIWindow.motionEnded` üzerinden tüm uygulama için tek noktadan yapılır.
/// Bu, SwiftUI/UIKit ayrımı olmadan çalışan yaygın (de-facto) yaklaşımdır.
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .logFoxShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}
#endif
