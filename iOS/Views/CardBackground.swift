import SwiftUI

extension View {
    /// Liquid Glass card on iOS 26+, material on iOS 18–25.
    @ViewBuilder
    func cardBackground() -> some View {
        if #available(iOS 26, *) {
            glassEffect(in: .rect(cornerRadius: 12))
        } else {
            background(.regularMaterial, in: .rect(cornerRadius: 12))
        }
    }
}
