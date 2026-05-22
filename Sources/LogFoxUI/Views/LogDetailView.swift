#if canImport(UIKit)
import SwiftUI
import LogFoxCore

/// Tek kaydın tam detayı. `.network` kayıtları bölümlü (summary/header/body) gösterilir;
/// diğerleri seviye + metadata olarak. Tüm metinler kopyalanabilir.
struct LogDetailView: View {
    let entry: LogEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let network = NetworkLogInfo(entry: entry) {
                    networkContent(network)
                } else {
                    logContent
                }
            }
            .padding()
        }
        .navigationTitle(NetworkLogInfo(entry: entry) != nil ? "Network" : "Log Detayı")
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

    // MARK: - Network içeriği

    @ViewBuilder
    private func networkContent(_ info: NetworkLogInfo) -> some View {
        HStack(spacing: 10) {
            StatusPill(statusCode: info.statusCode, isFailure: info.isFailure)
            MethodBadge(method: info.method ?? "GET")
            if let ms = info.durationMs {
                Text("\(ms)ms").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
        }

        section("URL") {
            Text(info.url ?? "-").font(.callout.monospaced()).textSelection(.enabled)
        }

        if let error = info.error {
            section("Hata") {
                Text(error).font(.callout).foregroundStyle(.red).textSelection(.enabled)
            }
        }

        let sizes = [
            info.requestBytes.map { "İstek \(Formatting.byteCount($0))" },
            info.responseBytes.map { "Yanıt \(Formatting.byteCount($0))" }
        ].compactMap { $0 }
        if !sizes.isEmpty {
            field("Boyut", sizes.joined(separator: " · "))
        }

        if !info.requestHeaders.isEmpty {
            section("İstek Header'ları") { headerList(info.requestHeaders) }
        }
        if let body = info.requestBody, !body.isEmpty {
            section("İstek Gövdesi") { CodeBlock(text: body) }
        }
        if !info.responseHeaders.isEmpty {
            section("Yanıt Header'ları") { headerList(info.responseHeaders) }
        }
        if let body = info.responseBody, !body.isEmpty {
            section("Yanıt Gövdesi") { CodeBlock(text: body) }
        }
    }

    @ViewBuilder
    private func headerList(_ headers: [(key: String, value: String)]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(headers, id: \.key) { header in
                HStack(alignment: .top, spacing: 8) {
                    Text(header.key).font(.caption.weight(.semibold))
                    Spacer(minLength: 8)
                    Text(header.value).font(.caption.monospaced()).foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing).textSelection(.enabled)
                }
            }
        }
    }

    // MARK: - Log içeriği

    @ViewBuilder
    private var logContent: some View {
        field("Seviye", "\(entry.level.symbol) \(entry.level.name)", color: entry.level.color)
        field("Kategori", entry.category.rawValue)
        field("Zaman", entry.date.formatted(date: .numeric, time: .standard))
        field("Thread", entry.thread)
        field("Kaynak", "\(entry.fileName):\(entry.line) — \(entry.function)")

        section("Mesaj") {
            Text(entry.message).font(.callout.monospaced()).textSelection(.enabled)
        }

        if !entry.metadata.isEmpty {
            section("Metadata") {
                ForEach(entry.metadata.sorted { $0.key < $1.key }, id: \.key) { key, value in
                    HStack(alignment: .top) {
                        Text(key).font(.caption.weight(.semibold))
                        Spacer(minLength: 8)
                        Text(value).font(.caption.monospaced()).foregroundStyle(.secondary).textSelection(.enabled)
                    }
                }
            }
        }
    }

    // MARK: - Yardımcılar

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
            Text(title.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            content()
        }
    }
}

/// Gövde/JSON için monospace kod bloğu; JSON ise pretty-print + kopyalama.
private struct CodeBlock: View {
    let text: String

    var body: some View {
        let display = Formatting.isJSON(text) ? Formatting.prettyJSON(text) : text
        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                Text(display)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .padding(10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button {
                UIPasteboard.general.string = display
            } label: {
                Label("Kopyala", systemImage: "doc.on.doc").font(.caption2)
            }
        }
    }
}
#endif
