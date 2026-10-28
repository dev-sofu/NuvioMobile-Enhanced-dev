import SwiftUI
import UIKit
import GoogleCast
import Network

/// Native Cast entry point for the iOS app.
enum NuvioCastController {
    private static var configured = false
    private static var localNetworkBrowser: NWBrowser?

    static func configureIfNeeded() {
        guard !configured else { return }
        let options = GCKCastOptions(receiverApplicationID: kGCKDefaultMediaReceiverApplicationID)
        GCKCastContext.setSharedInstanceWith(options)
        configured = true
    }

    /// Starts a real Bonjour browse when the user taps Cast. iOS presents its
    /// Local Network permission alert when this operation first accesses the
    /// local network, provided the app's Info.plist contains the required keys.
    static func requestLocalNetworkAccessForCast() {
        guard localNetworkBrowser == nil else { return }

        let browser = NWBrowser(
            for: .bonjour(type: "_googlecast._tcp", domain: nil),
            using: .tcp
        )
        browser.stateUpdateHandler = { state in
            switch state {
            case .failed(let error):
                print("Nuvio Cast local-network browser failed: \(error)")
                browser.cancel()
                if localNetworkBrowser === browser {
                    localNetworkBrowser = nil
                }
            case .cancelled:
                if localNetworkBrowser === browser {
                    localNetworkBrowser = nil
                }
            default:
                break
            }
        }
        localNetworkBrowser = browser
        browser.start(queue: .main)
    }
}

struct NuvioCastButton: UIViewRepresentable {
    func makeUIView(context: Context) -> GCKUICastButton {
        let button = GCKUICastButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
        button.tintColor = .white
        button.backgroundColor = .clear
        button.setImage(UIImage(systemName: "airplayvideo"), for: .normal)
        button.accessibilityLabel = "Cast to a device"
        button.isUserInteractionEnabled = true
        return button
    }

    func updateUIView(_ uiView: GCKUICastButton, context: Context) {
        uiView.tintColor = .white
        if uiView.image(for: .normal) == nil {
            uiView.setImage(UIImage(systemName: "airplayvideo"), for: .normal)
        }
    }
}
