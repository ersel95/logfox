import Foundation
import LogFoxCore

/// LogFox network capture yapılandırması.
public struct LogFoxNetworkConfiguration: Sendable {

    /// İstek/yanıt gövdelerini de logla. **Varsayılan açık.** (Gövdeler yine BankingRedactor'dan
    /// geçer; yine de keyfi JSON'daki her PII garanti yakalanamaz — gerekirse `false` yapın.)
    public var capturesBodies: Bool

    /// İstek/yanıt header'larını da logla. **Varsayılan açık** (hassas header'lar redaksiyondan geçer).
    public var capturesHeaders: Bool

    /// Gövde loglanırken kesilecek maksimum karakter sayısı.
    public var maxBodyLength: Int

    /// Network kayıtlarının düşeceği kategori.
    public var category: LogCategory

    public init(
        capturesBodies: Bool = true,
        capturesHeaders: Bool = true,
        maxBodyLength: Int = 8000,
        category: LogCategory = .network
    ) {
        self.capturesBodies = capturesBodies
        self.capturesHeaders = capturesHeaders
        self.maxBodyLength = max(0, maxBodyLength)
        self.category = category
    }

    public static let `default` = LogFoxNetworkConfiguration()
}
