import Foundation

/// LogFox viewer'ından başka bir tanılama aracına (örn. Netfox) geçişi temsil eder.
///
/// Paket bilinçli olarak Netfox'a bağlı **değildir**: uygulama kendi `NetfoxBridge`'ini
/// bu protokole uydurup `LogFoxUI.register(_:)` ile kaydeder. Böylece Netfox kullanmayan
/// projeler LogFox'u temiz alır; kayıtlı köprü yoksa viewer'da buton görünmez.
public protocol ExternalToolBridge: Sendable {
    /// Viewer toolbar'ında görünecek başlık (örn. "Netfox").
    var title: String { get }
    /// Sistem sembol adı (SF Symbol), opsiyonel.
    var systemImage: String? { get }
    /// Aracı aç. LogFox viewer'ı kapatmak çağıranın sorumluluğundadır (genelde önce dismiss).
    @MainActor func open()
}

public extension ExternalToolBridge {
    var systemImage: String? { nil }
}

/// Kayıtlı dış araç köprülerinin süreç-geneli kaydı. Thread-safe.
final class ExternalToolRegistry: @unchecked Sendable {

    static let shared = ExternalToolRegistry()

    private let lock = NSLock()
    private var bridges: [any ExternalToolBridge] = []

    func register(_ bridge: any ExternalToolBridge) {
        lock.lock(); defer { lock.unlock() }
        bridges.append(bridge)
    }

    func removeAll() {
        lock.lock(); defer { lock.unlock() }
        bridges.removeAll()
    }

    var all: [any ExternalToolBridge] {
        lock.lock(); defer { lock.unlock() }
        return bridges
    }
}
