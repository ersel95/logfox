import Foundation

/// Görüntüleme yardımcıları: JSON pretty-print ve byte boyutu biçimleme.
enum Formatting {

    /// Geçerli JSON ise girintili biçimde döndürür; değilse metni olduğu gibi verir.
    static func prettyJSON(_ text: String) -> String {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
              ),
              let string = String(data: pretty, encoding: .utf8) else {
            return text
        }
        return string
    }

    /// İçerik JSON mı? (detayda monospace + pretty uygulanır.)
    static func isJSON(_ text: String) -> Bool {
        guard let data = text.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    static func byteCount(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .binary)
    }
}
