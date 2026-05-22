# LogFox — YapiKredi Azerbaijan Entegrasyon Rehberi

Bu dosya, LogFox'u uygulamaya `NetfoxManager` ile aynı paterni izleyerek bağlamak için **hazır-yapıştır** referans kod içerir. Paket Netfox'tan bağımsızdır; Netfox geçişi app tarafında bir köprü ile kurulur.

> **Gating notu:** TestFlight build'i genelde UAT/Prod config'tedir; `#if DEBUG` yalnız Test config'te tanımlıdır. LogFox'u `#if DEBUG`'a bağlama — **runtime feature flag** kullan (aşağıda `Feature.isEnabled(.logFox)`). PROD davranışını sen manuel ayarlayacaksın.

---

## 1. Paketi ekle

Xcode → Add Packages → `https://github.com/ersel95/logfox` → ana app target'ına:
- `LogFoxCore`
- `LogFoxUI`

(WalletExtension target'larına yalnız `LogFoxCore`, istenirse.)

---

## 2. `LogFoxManager.swift` (NetfoxManager muadili)

`Core/Utils/LogFoxManager.swift`:

```swift
import Foundation
import LogFoxCore
import LogFoxUI

/// LogFox yaşam döngüsünü yöneten entegrasyon noktası (NetfoxManager ile aynı patern).
final class LogFoxManager {

    static let shared = LogFoxManager()
    private init() {}

    /// İzin verilen ortamlar (NetfoxManager.isAllowedEnvironment ile aynı mantık).
    private var isAllowedEnvironment: Bool {
        // mevcut projedeki ortam kontrolünü buraya bağla
        true
    }

    func initialize() {
        #if !PROD
        if Feature.isDisabled(.logFox) {
            guard isAllowedEnvironment else { return }
        }

        // 1) Çekirdeği başlat (redaksiyon açık, diske yazar, OSLog'a yansıtır)
        LogFox.start(.bankingDefault)

        // 2) Shake → viewer (LogFox shake sahibidir)
        Task { @MainActor in
            LogFoxUI.install()
            // 3) Netfox geçiş butonunu kaydet (Netfox da açıksa)
            LogFoxUI.register(NetfoxBridge())
        }
        #endif
        // PROD davranışı: burada bilinçli olarak kapalı. Gerekirse remote-flag ile aç.
    }
}
```

> `Feature.isDisabled(.logFox)` için `FeatureManager`'a `.logFox` case'i ekle (`.netfox` ile aynı şekilde).

---

## 3. `NetfoxBridge.swift` (LogFox → Netfox geçişi)

`Core/Utils/NetfoxBridge.swift`:

```swift
import LogFoxUI
import netfox   // projede Netfox modülünün import adı

/// Viewer'daki "Netfox" butonunu Netfox'a bağlar. Önce LogFox kapanır, sonra Netfox açılır.
struct NetfoxBridge: ExternalToolBridge {
    let title = "Netfox"
    var systemImage: String? { "network" }

    @MainActor func open() {
        LogFoxUI.dismiss()
        NFX.sharedInstance().show()
    }
}
```

---

## 4. Netfox'u shake'ten çıkar (çakışma çözümü)

`NetfoxManager.initialize()` içinde, `NFX.sharedInstance().start()` çağrısından sonra:

```swift
NFX.sharedInstance().start()
NFX.sharedInstance().setGesture(.custom)   // shake artık LogFox'a ait
```

Böylece **shake → LogFox açılır**; LogFox viewer'ındaki "Netfox" butonu Netfox'a geçirir.

---

## 5. App init'te bağla

`Application/YapiKredi_AzApp.swift` (mevcut Netfox init'inin yanına):

```swift
DispatchQueue.main.async {
    NetfoxManager.shared.initialize()   // içinde setGesture(.custom) eklendi
    LogFoxManager.shared.initialize()
}
```

---

## 6. Developer Options toggle (opsiyonel)

`DeveloperConfigView`'a "LogFox" satırı: aç/kapat → `LogFox.isEnabled`, ayrıca "Logları göster" (`LogFoxUI.present()`), "Temizle" (`LogFox.clear()`), "Paylaş" (`LogFox.exportFileURL()`).

---

## 7. Kullanım — `print()` yerine

```swift
// önce:
print("⚠️ token decode hatası")
// sonra:
LogFox.warning("token decode hatası", category: .security)
```

Kademeli göç önerilir: önce paket + viewer çalışsın, sonra çağrı yerleri taşınsın. Network logları Netfox'ta kalır; LogFox'a yalnız üst-seviye iş olayları girer.
