import SwiftUI

struct MusicBarsAnimation: View {
    let isPlaying: Bool
    
    @State private var bar1Height: CGFloat = 0.4
    @State private var bar1Opacity: Double = 0.7
    
    @State private var bar2Height: CGFloat = 0.6
    @State private var bar2Opacity: Double = 0.75
    
    @State private var bar3Height: CGFloat = 0.5
    @State private var bar3Opacity: Double = 0.7
    
    @State private var bar4Height: CGFloat = 0.65
    @State private var bar4Opacity: Double = 0.75
    
    @State private var bar5Height: CGFloat = 0.45
    @State private var bar5Opacity: Double = 0.7
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        HStack(alignment: .center, spacing: 1.5) {
            BarView(height: bar1Height, opacity: bar1Opacity)
            BarView(height: bar2Height, opacity: bar2Opacity)
            BarView(height: bar3Height, opacity: bar3Opacity)
            BarView(height: bar4Height, opacity: bar4Opacity)
            BarView(height: bar5Height, opacity: bar5Opacity)
        }
        .onAppear {
            if isPlaying && !reduceMotion {
                startAnimation()
            }
        }
        .onChange(of: isPlaying) { _, newValue in
            if newValue && !reduceMotion {
                startAnimation()
            } else {
                resetToDefault()
            }
        }
        .onChange(of: reduceMotion) { _, newValue in
            if newValue {
                resetToDefault()
            } else if isPlaying {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        // Bar 1: subtle motion with slight pause at top
        withAnimation(
            Animation.timingCurve(0.17, 0.67, 0.83, 0.67, duration: 1.8)
                .repeatForever(autoreverses: true)
        ) {
            bar1Height = 0.75
            bar1Opacity = 0.85
        }
        
        // Bar 2: different rhythm, leads slightly ahead
        withAnimation(
            Animation.timingCurve(0.17, 0.67, 0.83, 0.67, duration: 1.5)
                .repeatForever(autoreverses: true)
                .delay(0.1)
        ) {
            bar2Height = 0.8
            bar2Opacity = 0.9
        }
        
        // Bar 3: middle bar, slower cadence
        withAnimation(
            Animation.timingCurve(0.17, 0.67, 0.83, 0.67, duration: 2.0)
                .repeatForever(autoreverses: true)
                .delay(0.25)
        ) {
            bar3Height = 0.7
            bar3Opacity = 0.8
        }
        
        // Bar 4: mirrors bar 2 roughly
        withAnimation(
            Animation.timingCurve(0.17, 0.67, 0.83, 0.67, duration: 1.6)
                .repeatForever(autoreverses: true)
                .delay(0.15)
        ) {
            bar4Height = 0.82
            bar4Opacity = 0.88
        }
        
        // Bar 5: fastest, creates sense of motion
        withAnimation(
            Animation.timingCurve(0.17, 0.67, 0.83, 0.67, duration: 1.4)
                .repeatForever(autoreverses: true)
                .delay(0.05)
        ) {
            bar5Height = 0.72
            bar5Opacity = 0.82
        }
    }
    
    private func resetToDefault() {
        withAnimation(.easeInOut(duration: 0.3)) {
            bar1Height = 0.4
            bar1Opacity = 0.7
            bar2Height = 0.6
            bar2Opacity = 0.75
            bar3Height = 0.5
            bar3Opacity = 0.7
            bar4Height = 0.65
            bar4Opacity = 0.75
            bar5Height = 0.45
            bar5Opacity = 0.7
        }
    }
}

private struct BarView: View {
    let height: CGFloat
    let opacity: Double
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.white.opacity(opacity))
            .frame(width: 1.5, height: 8 * height)
    }
}






