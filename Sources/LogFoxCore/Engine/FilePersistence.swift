import Foundation

/// Logları diske yazar, boyut bazlı rotation ve dosya-sayısı retention uygular.
///
/// Bu tip **kendi başına thread-safe değildir**; yalnızca `LogStore`'un serial
/// kuyruğundan çağrılır. `@unchecked Sendable` bu sözleşmeye dayanır.
final class FilePersistence: @unchecked Sendable {

    private let directory: URL
    private let maxFileSize: Int
    private let maxFileCount: Int
    private let fileManager = FileManager.default

    private let activeFileName = "logfox-current.log"
    private let rotatedPrefix = "logfox-"
    private let fileExtension = "log"

    private var handle: FileHandle?
    private var currentSize: Int = 0

    init?(directory: URL, maxFileSize: Int, maxFileCount: Int) {
        self.directory = directory
        self.maxFileSize = maxFileSize
        self.maxFileCount = maxFileCount

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try openActiveFile()
            pruneOldFiles()
        } catch {
            return nil
        }
    }

    deinit {
        try? handle?.close()
    }

    // MARK: - Yazma

    func write(_ line: String) {
        guard let handle, let data = (line + "\n").data(using: .utf8) else { return }
        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            currentSize += data.count
            if currentSize >= maxFileSize {
                rotate()
            }
        } catch {
            // Disk hatası logging'i çökertmemeli; sessizce geç.
        }
    }

    // MARK: - Temizleme & export

    func clear() {
        try? handle?.close()
        handle = nil
        for url in allLogFiles() {
            try? fileManager.removeItem(at: url)
        }
        try? openActiveFile()
    }

    /// Tüm dosyaları (eskiden yeniye) tek bir export dosyasında birleştirir.
    func consolidatedFileURL() -> URL? {
        try? handle?.synchronize()
        let files = rotatedFilesSortedAscending() + [activeFileURL]
        let exportURL = fileManager.temporaryDirectory
            .appendingPathComponent("logfox-export-\(Int(Date().timeIntervalSince1970)).log")

        fileManager.createFile(atPath: exportURL.path, contents: nil)
        guard let out = try? FileHandle(forWritingTo: exportURL) else { return nil }
        defer { try? out.close() }

        for file in files {
            guard let data = try? Data(contentsOf: file) else { continue }
            try? out.write(contentsOf: data)
        }
        return exportURL
    }

    // MARK: - Dahili

    private var activeFileURL: URL {
        directory.appendingPathComponent(activeFileName)
    }

    private func openActiveFile() throws {
        if !fileManager.fileExists(atPath: activeFileURL.path) {
            fileManager.createFile(atPath: activeFileURL.path, contents: nil)
        }
        applyProtection(to: activeFileURL)
        let handle = try FileHandle(forWritingTo: activeFileURL)
        self.handle = handle
        self.currentSize = (try? handle.seekToEnd()).map(Int.init) ?? 0
    }

    private func rotate() {
        try? handle?.close()
        handle = nil

        let rotatedURL = directory.appendingPathComponent(
            "\(rotatedPrefix)\(Int(Date().timeIntervalSince1970)).\(fileExtension)"
        )
        try? fileManager.moveItem(at: activeFileURL, to: rotatedURL)

        currentSize = 0
        try? openActiveFile()
        pruneOldFiles()
    }

    /// `maxFileCount`'u aşan en eski rotated dosyaları siler (aktif dosya hariç).
    private func pruneOldFiles() {
        let rotated = rotatedFilesSortedAscending()
        // Aktif dosya da sayıma dahil → en fazla (maxFileCount - 1) rotated tutulur.
        let allowedRotated = max(0, maxFileCount - 1)
        guard rotated.count > allowedRotated else { return }
        for url in rotated.prefix(rotated.count - allowedRotated) {
            try? fileManager.removeItem(at: url)
        }
    }

    private func allLogFiles() -> [URL] {
        rotatedFilesSortedAscending() + [activeFileURL]
    }

    private func rotatedFilesSortedAscending() -> [URL] {
        let contents = (try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey]
        )) ?? []

        return contents
            .filter {
                $0.lastPathComponent.hasPrefix(rotatedPrefix)
                    && $0.lastPathComponent != activeFileName
                    && $0.pathExtension == fileExtension
            }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func applyProtection(to url: URL) {
        // İlk kilit açılışına kadar şifreli; banking-grade taban koruma.
        // `FileProtectionType` yalnız iOS/iPadOS'ta mevcut (macOS test build'inde no-op).
        #if os(iOS)
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: url.path
        )
        #endif
    }
}
