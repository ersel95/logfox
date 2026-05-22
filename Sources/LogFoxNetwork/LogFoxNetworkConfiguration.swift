import Foundation
import LogFoxCore

/// LogFox network capture yapılandırması.
public struct LogFoxNetworkConfiguration: Sendable {

    /// İstek/yanıt gövdelerini de logla. **Varsayılan kapalı** (banking-grade: gövdeler
    /// keyfi PII içerebilir; açılırsa yine BankingRedactor'dan geçer ama yine de dikkat).
    public var capturesBodies: Bool

    /// Gövde loglanırken kesilecek maksimum karakter sayısı.
    public var maxBodyLength: Int

    /// Network kayıtlarının düşeceği kategori.
    public var category: LogCategory

    public init(
        capturesBodies: Bool = false,
        maxBodyLength: Int = 2000,
        category: LogCategory = .network
    ) {
        self.capturesBodies = capturesBodies
        self.maxBodyLength = max(0, maxBodyLength)
        self.category = category
    }

    public static let `default` = LogFoxNetworkConfiguration()
}
