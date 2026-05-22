import Foundation
import LogFoxCore

/// LogFoxUI'ın genel cephesi: shake → viewer kurulumu, dış araç (Netfox) kaydı, programatik sunum.
///
/// ```swift
/// LogFox.start(.bankingDefault)
/// LogFoxUI.install()                       // shake → viewer
/// LogFoxUI.register(NetfoxBridge())        // app tarafında tanımlı köprü
/// ```
public enum LogFoxUI {

    /// Cihaz sallandığında viewer'ı açacak gözlemciyi kurar. İdempotent; bir kez çağırın.
    @MainActor
    public static func install() {
        #if canImport(UIKit)
        LogFoxPresenter.shared.installShakeObserver()
        #endif
    }

    /// Dış tanılama aracı köprüsü kaydeder (örn. Netfox). Viewer'da geçiş butonu olarak görünür.
    public static func register(_ bridge: any ExternalToolBridge) {
        ExternalToolRegistry.shared.register(bridge)
    }

    /// Kayıtlı tüm dış araçları kaldırır.
    public static func unregisterAllTools() {
        ExternalToolRegistry.shared.removeAll()
    }

    /// Viewer'ı programatik aç.
    @MainActor
    public static func present() {
        #if canImport(UIKit)
        LogFoxPresenter.shared.present()
        #endif
    }

    /// Viewer'ı programatik kapat.
    @MainActor
    public static func dismiss() {
        #if canImport(UIKit)
        LogFoxPresenter.shared.dismiss()
        #endif
    }
}
