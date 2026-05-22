import Foundation

/// LogFox network capture cephesi. Uygulamanın network isteklerini yakalayıp `.network`
/// kategorisinde (redakte edilerek) LogFox'a loglar.
///
/// ```swift
/// // Tüm istekleri yakalamak için (Alamofire/URLSession custom config):
/// LogFoxNetwork.install(into: sessionConfiguration)
///
/// // veya shared URLSession için global:
/// LogFoxNetwork.installGlobally()
/// ```
public enum LogFoxNetwork {

    private static let box = ConfigBox()

    /// Aktif yapılandırma. `LogFox.start` öncesi/sonrası ayarlanabilir.
    public static var configuration: LogFoxNetworkConfiguration {
        get { box.value }
        set { box.value = newValue }
    }

    /// Yakalama protokolünü verilen `URLSessionConfiguration`'a enjekte eder ve yakalama
    /// parametrelerini **init'te** ayarlar (mevcut `NFXProtocol` enjeksiyonuyla aynı patern).
    /// - Parameters:
    ///   - configuration: Protokolün başa ekleneceği session config.
    ///   - networkConfiguration: Yakalama filtreleri (gövde/header default açık).
    public static func install(
        into configuration: URLSessionConfiguration,
        with networkConfiguration: LogFoxNetworkConfiguration = .default
    ) {
        self.configuration = networkConfiguration
        var classes = configuration.protocolClasses ?? []
        classes.insert(LogFoxURLProtocol.self, at: 0)
        configuration.protocolClasses = classes
    }

    /// `URLSession.shared` ve global istekler için protokolü kaydeder ve yakalama parametrelerini init'te ayarlar.
    public static func installGlobally(_ networkConfiguration: LogFoxNetworkConfiguration = .default) {
        self.configuration = networkConfiguration
        URLProtocol.registerClass(LogFoxURLProtocol.self)
    }

    /// Global kaydı kaldırır.
    public static func uninstallGlobally() {
        URLProtocol.unregisterClass(LogFoxURLProtocol.self)
    }

    /// Manuel enjeksiyon için protokol sınıfı.
    public static var protocolClass: AnyClass { LogFoxURLProtocol.self }

    // Dahili erişim (URLProtocol config'i okur).
    static var current: LogFoxNetworkConfiguration { box.value }

    private final class ConfigBox: @unchecked Sendable {
        private let lock = NSLock()
        private var _value = LogFoxNetworkConfiguration.default
        var value: LogFoxNetworkConfiguration {
            get { lock.lock(); defer { lock.unlock() }; return _value }
            set { lock.lock(); _value = newValue; lock.unlock() }
        }
    }
}
