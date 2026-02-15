import SwiftUI

/// Provides Liquid Glass on macOS 26+ with an `.ultraThinMaterial` fallback on older systems.
struct AdaptiveGlassModifier<S: Shape>: ViewModifier {
    let interactive: Bool
    let shape: S

    @State private var isHovered = false

    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            if interactive {
                content.glassEffect(.regular.interactive(), in: shape)
            } else {
                content.glassEffect(in: shape)
            }
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    if interactive && isHovered {
                        shape.fill(.white.opacity(0.07))
                    }
                }
                .onHover { hovering in
                    if interactive { isHovered = hovering }
                }
        }
    }
}

extension View {
    /// Adaptive glass card — Liquid Glass on macOS 26+, material on older systems.
    func adaptiveGlass<S: Shape>(in shape: S) -> some View {
        modifier(AdaptiveGlassModifier(interactive: false, shape: shape))
    }

    /// Adaptive interactive glass button — adds hover highlight on pre-Tahoe.
    func adaptiveGlass<S: Shape>(_ style: AdaptiveGlassStyle, in shape: S) -> some View {
        modifier(AdaptiveGlassModifier(interactive: true, shape: shape))
    }
}

/// Marker enum for the interactive call-site syntax: `.adaptiveGlass(.interactive, in:)`.
enum AdaptiveGlassStyle {
    case interactive
}
