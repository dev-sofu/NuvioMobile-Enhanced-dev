import SwiftUI
import UIKit
import GoogleCast

/// Minimal native Cast entry point for the iOS app.
/// Playback handoff is intentionally a separate milestone; this first step
/// configures the Cast SDK and exposes its standard receiver picker.
enum NuvioCastController {
    private static var configured = false

    static func configureIfNeeded() {
        guard !configured else { return }
        let options = GCKCastOptions(receiverApplicationID: kGCKDefaultMediaReceiverApplicationID)
        GCKCastContext.setSharedInstanceWith(options)
        configured = true
    }
}

struct NuvioCastButton: UIViewRepresentable {
    func makeUIView(context: Context) -> GCKUICastButton {
        let button = GCKUICastButton(frame: .zero)
        button.tintColor = .white
        button.accessibilityLabel = "Cast to a device"
        return button
    }

    func updateUIView(_ uiView: GCKUICastButton, context: Context) {
        uiView.tintColor = .white
    }
}
