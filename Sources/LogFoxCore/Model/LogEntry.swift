import Foundation

/// Tek bir log kaydı. `message` ve `metadata` redaksiyondan **geçmiş** haliyle saklanır;
/// ham PII hiçbir zaman bu yapıya ulaşmaz (bkz. `Redactor`).
public struct LogEntry: Identifiable, Sendable, Codable, Hashable {
    public let id: UUID
    public let date: Date
    public let level: LogLevel
    public let category: LogCategory
    public let message: String
    public let metadata: [String: String]
    public let file: String
    public let line: Int
    public let function: String
    public let thread: String

    public init(
        id: UUID = UUID(),
        date: Date,
        level: LogLevel,
        category: LogCategory,
        message: String,
        metadata: [String: String],
        file: String,
        line: Int,
        function: String,
        thread: String
    ) {
        self.id = id
        self.date = date
        self.level = level
        self.category = category
        self.message = message
        self.metadata = metadata
        self.file = file
        self.line = line
        self.function = function
        self.thread = thread
    }

    /// `#fileID` "Module/Sub/File.swift" verir; viewer'da yalnız dosya adını göstermek için.
    public var fileName: String {
        (file as NSString).lastPathComponent
    }
}
