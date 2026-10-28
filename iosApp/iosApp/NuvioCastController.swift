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

    /// Starts a Bonjour browse when the user taps Cast and logs its state so
    /// Local Network permission failures can be distinguished from no devices.
    static func requestLocalNetworkAccessForCast() {
        guard localNetworkBrowser == nil else {
            print("Nuvio Cast diagnostics: Bonjour browser already running")
            return
        }

        print("Nuvio Cast diagnostics: starting Bonjour browse for _googlecast._tcp")
        let browser = NWBrowser(
            for: .bonjour(type: "_googlecast._tcp", domain: nil),
            using: .tcp
        )

        browser.stateUpdateHandler = { state in
            switch state {
            case .setup:
                print("Nuvio Cast diagnostics: browser state = setup")
            case .ready:
                print("Nuvio Cast diagnostics: browser state = ready")
            case .waiting(let error):
                print("Nuvio Cast diagnostics: browser state = waiting; error = \(String(reflecting: error))")
                if case .dns(let code) = error, Int(code) == -65570 {
                    print("Nuvio Cast diagnostics: DNS policy denied; Local Network access is not granted")
                }
                if case .posix(let code) = error, code == .EACCES {
                    print("Nuvio Cast diagnostics: POSIX access denied")
                }
            case .failed(let error):
                print("Nuvio Cast diagnostics: browser state = failed; error = \(String(reflecting: error))")
                browser.cancel()
                if localNetworkBrowser === browser {
                    localNetworkBrowser = nil
                }
            case .cancelled:
                print("Nuvio Cast diagnostics: browser state = cancelled")
                if localNetworkBrowser === browser {
                    localNetworkBrowser = nil
                }
            @unknown default:
                print("Nuvio Cast diagnostics: browser state = unknown")
            }
        }

        browser.browseResultsChangedHandler = { results, changes in
            print("Nuvio Cast diagnostics: browse results changed; count = \(results.count)")
            for result in results {
                print("Nuvio Cast diagnostics: discovered service = \(result.endpoint)")
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
