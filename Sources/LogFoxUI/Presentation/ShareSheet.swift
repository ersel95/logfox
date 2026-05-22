#if canImport(UIKit)
import SwiftUI
import UIKit

/// `UIActivityViewController` SwiftUI sarmalayıcısı — log dosyasını paylaşmak için.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
#endif
