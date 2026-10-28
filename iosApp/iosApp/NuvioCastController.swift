import SwiftUI
import UIKit
import GoogleCast

/// Native Cast entry point for the iOS app.
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
