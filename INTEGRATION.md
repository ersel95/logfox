# LogFox — Entegrasyon Rehberi

LogFox'u uygulamaya, **Netfox** ve **Pulse** ile uyumlu olacak şekilde bağlamak için rehber.

> **Tasarım ilkesi:** Paket Netfox/Pulse'a **bağlı değildir**. Bu araçlara geçiş host app tarafında, `#if canImport(...)` ile opsiyonel olarak kurulur. Bir projede **yalnız bir** network logger aktiftir; host hangisini kullandığını bir enum (`.netfox` / `.pulse` / `.none`) ile **init sırasında** seçer. Hızlı yol için: tek-dosya template [`Integration/LogFoxIntegration.swift`](Integration/LogFoxIntegration.swift) ve makine-takipli [`AGENTS.md`](AGENTS.md).

> **Gating notu:** TestFlight build'i genelde UAT/Prod config'tedir; `#if DEBUG` yalnız Test config'te tanımlıdır. LogFox'u `#if DEBUG`'a bağlama — **runtime feature flag** kullan. PROD davranışını siz ayarlarsınız.

---

## Neden `canImport` host tarafında?

`#if canImport(PulseUI)` derleme zamanında **modül o target'a link'liyse** doğrudur. LogFox paketi Netfox/Pulse'a bağlı olmadığından, paket içinde `canImport(PulseUI)` **her zaman `false`** döner. Bu yüzden tespit, Netfox/Pulse'ın gerçekten link'lendiği **host app**'te yapılır. Host, sonucu (etkin köprüler listesini) init'te pakete verir → "karar SPM'e init'te gönderilir".

```
Host app  ──(seçili logger: .netfox/.pulse/.none + canImport)──►  LogFoxUI.install(tools: [...])
                                                                        │
shake ──► LogFox viewer ──► [Netfox] veya [Pulse] butonu (seçilen tek araç)
```

---

## 1. Paketi ekle

Xcode → Add Packages → `https://github.com/ersel95/logfox` → ana app target'ına:
- `LogFoxCore`
- `LogFoxUI`
- `LogFoxNetwork` *(opsiyonel — network loglarını LogFox'ta görmek isterseniz, §7)*

(App extension'lara yalnız `LogFoxCore`.)

## 2. Entegrasyon dosyasını kopyala

[`Integration/LogFoxIntegration.swift`](Integration/LogFoxIntegration.swift) dosyasını host app'e (örn. `Core/Utils/`) kopyalayın. İçinde `LogFoxManager`, `LogFoxNetworkLogger` enum'u ve canImport-gate'li `NetfoxBridge` + `PulseBridge` hazırdır. `// ADAPT:` satırlarını uyarlayın.

Özet (tam içerik template dosyasında):

```swift
import LogFoxCore
import LogFoxUI
#if canImport(netfox)
import netfox
#endif
#if canImport(PulseUI)
import PulseUI
#endif

/// Projede aktif olan tek network logger.
public enum LogFoxNetworkLogger { case netfox, pulse, none }

public final class LogFoxManager {
    public static let shared = LogFoxManager()
    private init() {}

    public func initialize(networkLogger: LogFoxNetworkLogger = .none) {
        #if !PROD
        LogFox.start(.bankingDefault)
        Task { @MainActor in
            var bridges: [any ExternalToolBridge] = []
            switch networkLogger {
            case .netfox:
                #if canImport(netfox)
                bridges.append(NetfoxBridge())
                #endif
            case .pulse:
                #if canImport(PulseUI)
                bridges.append(PulseBridge())
                #endif
            case .none:
                break
            }
            LogFoxUI.install(tools: bridges)
        }
        #endif
    }
}
```

### Netfox köprüsü (kendini sunan UIKit aracı)
```swift
#if canImport(netfox)
struct NetfoxBridge: ExternalToolBridge {
    let title = "Netfox"
    var systemImage: String? { "network" }
    @MainActor func open() {
        LogFoxUI.dismiss()
        NFX.sharedInstance().show()
    }
}
#endif
```

### Pulse köprüsü (gömülebilir SwiftUI aracı)
```swift
#if canImport(PulseUI)
struct PulseBridge: ExternalToolBridge {
    let title = "Pulse"
    var systemImage: String? { "waveform.path.ecg" }
    @MainActor func open() {
        LogFoxUI.presentExternal { PulseConsoleScreen() }
    }
}

private struct PulseConsoleScreen: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ConsoleView()
                .navigationTitle("Pulse")
                .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Kapat") { dismiss() } } }
        }
    }
}
#endif
```

> **İki sunum modeli:** Netfox kendi penceresinde açılır → köprü `dismiss()` + `NFX.show()` yapar. Pulse gömülebilir bir SwiftUI ekranıdır → `LogFoxUI.presentExternal { ... }` ile LogFox'un kendi penceresi üzerinde modal sunulur; "Kapat" LogFox viewer'a döner.

## 3. Başlatmayı bağla

`Application/YapiKredi_AzApp.swift` (mevcut Netfox init'inin yanına):
```swift
DispatchQueue.main.async {
    NetfoxManager.shared.initialize()   // (Netfox kullanılıyorsa) içinde setGesture(.custom)
    LogFoxManager.shared.initialize(networkLogger: .netfox)   // .netfox / .pulse / .none
}
```

## 4. Netfox'u shake'ten çıkar (çakışma çözümü)

`NetfoxManager.initialize()` içinde, `NFX.sharedInstance().start()` ardına:
```swift
NFX.sharedInstance().setGesture(.custom)   // shake artık LogFox'a ait
```
Böylece **shake → LogFox açılır**; içeriden Netfox/Pulse'a geçilir. (Pulse'ın shake'i yoktur, ek işlem gerekmez.)

## 5. Developer Options toggle (opsiyonel)

`DeveloperConfigView`'a "LogFox" satırı: `LogFox.isEnabled` aç/kapat, "Logları göster" (`LogFoxUI.present()`), "Temizle" (`LogFox.clear()`), "Paylaş" (`LogFox.exportFileURL()`).

## 6. (Opsiyonel) Network loglarını LogFox'ta listelemek — `LogFoxNetwork`

LogFox kendi `URLProtocol`'ü ile istek/yanıtları yakalayıp `.network` kategorisinde, **BankingRedactor'dan
geçirerek** (PAN/IBAN/token maskeli) loglar. Böylece app + network logları tek listede görünür; Netfox/Pulse'a
geçiş butonu derin inceleme için kalır.

```swift
import LogFoxNetwork

// (ops.) yapılandırma — gövde yakalama banking-grade nedeniyle default KAPALI:
LogFoxNetwork.configuration = LogFoxNetworkConfiguration(capturesBodies: false)

// A) Custom URLSession/Alamofire config (ÖNERİLEN — BaseService'te NFXProtocol enjeksiyonunun yanına):
//    configuration.protocolClasses başına LogFox protokolünü ekler.
LogFoxNetwork.install(into: sessionConfiguration)

// B) veya URLSession.shared / global istekler için:
LogFoxNetwork.installGlobally()
```

> **YapiKredi'de:** `BaseService` içinde `#if !PROD` ile `NFXProtocol` `configuration.protocolClasses`'a
> eklenen yere, `LogFoxNetwork.install(into: configuration)` satırını ekleyin. Network kayıtları viewer'da
> `network` kategori chip'iyle görünür, kategori filtresinden ayrılabilir.
>
> **Güvenlik:** `capturesBodies` açılırsa gövdeler de loglanır (yine redaksiyondan geçer ama keyfi JSON'daki
> her PII garanti yakalanamaz). Banking için kapalı bırakmanız önerilir.

## 7. `print()` → `LogFox` göçü

```swift
// önce:
print("⚠️ token decode hatası")
// sonra:
LogFox.warning("token decode hatası", category: .security)
```
Kademeli göç önerilir. Network logları Netfox/Pulse'ta kalır; LogFox'a yalnız üst-seviye iş olayları girer.

---

## Pulse hakkında not

Pulse'ın **network yakalaması** host'un kendi Pulse kurulumudur (`URLSessionProxyDelegate` / `Experimental.URLSessionProxy`) — LogFox kapsamı dışındadır. LogFox yalnız Pulse konsoluna **geçiş** sağlar. Pulse'ı kendi loglama backend'iniz olarak da kullanmak isterseniz, gelecekte LogFox için bir `swift-log` / Pulse köprüsü (Faz 4) eklenebilir.
