#if canImport(UIKit)
import SwiftUI
import LogFoxCore

/// Tek kaydın tam detayı; tüm metni kopyalanabilir.
struct LogDetailView: View {
    let entry: LogEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                field("Seviye", "\(entry.level.symbol) \(entry.level.name)", color: entry.level.color)
                field("Kategori", entry.category.rawValue)
                field("Zaman", entry.date.formatted(date: .numeric, time: .standard))
                field("Thread", entry.thread)
                field("Kaynak", "\(entry.fileName):\(entry.line) — \(entry.function)")

                section("Mesaj") {
                    Text(entry.message)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                }

                if !entry.metadata.isEmpty {
                    section("Metadata") {
                        ForEach(entry.metadata.sorted { $0.key < $1.key }, id: \.key) { key, value in
                            HStack(alignment: .top) {
                                Text(key).font(.caption.weight(.semibold))
                                Spacer(minLength: 8)
                                Text(value).font(.caption.monospaced()).textSelection(.enabled)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Log Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = entry.oneLineDescription
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .accessibilityLabel("Kopyala")
            }
        }
    }

    @ViewBuilder
    private func field(_ title: String, _ value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.callout).foregroundStyle(color).textSelection(.enabled)
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            content()
        }
    }
}
#endif
