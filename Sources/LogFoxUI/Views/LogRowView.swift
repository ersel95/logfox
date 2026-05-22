#if canImport(UIKit)
import SwiftUI
import LogFoxCore

/// Tek log satırı: zaman + seviye + kategori başlığı, altında mesaj (mono).
struct LogRowView: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(entry.level.symbol)
                Text(PlainTextFormatter.timeFormatter.string(from: entry.date))
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                Text(entry.level.name)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(entry.level.color)
                Text(entry.category.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.15), in: Capsule())
                Spacer(minLength: 0)
            }

            Text(entry.message)
                .font(.caption.monospaced())
                .foregroundStyle(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
#endif
