import SwiftUI

struct MusicBarsAnimation: View {
    let isPlaying: Bool
    
    @State private var bar1: CGFloat = 0.0
    @State private var bar2: CGFloat = 0.0
    @State private var bar3: CGFloat = 0.0
    @State private var bar4: CGFloat = 0.0
    
    @State private var animationTask: Task<Void, Never>?
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private let barWidth: CGFloat = 2.2
    private let barSpacing: CGFloat = 2.5
    private let maxHeight: CGFloat = 11.0
    private let dotSize: CGFloat = 2.2
    
    var body: some View {
        HStack(alignment: .center, spacing: barSpacing) {
            BarShape(height: bar1, isPlaying: isPlaying)
            BarShape(height: bar2, isPlaying: isPlaying)
            BarShape(height: bar3, isPlaying: isPlaying)
            BarShape(height: bar4, isPlaying: isPlaying)
        }
        .onAppear {
            if isPlaying && !reduceMotion {
                startAnimating()
            }
        }
        .onChange(of: isPlaying) { _, playing in
            animationTask?.cancel()
            if playing && !reduceMotion {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced {
                animationTask?.cancel()
                stopAnimating()
            } else if isPlaying {
                startAnimating()
            }
        }
    }
    
    private func startAnimating() {
        animationTask = Task {
            while !Task.isCancelled && isPlaying {
                let randomHeights = [
                    CGFloat.random(in: 0.4...0.95),
                    CGFloat.random(in: 0.3...0.9),
                    CGFloat.random(in: 0.45...1.0),
                    CGFloat.random(in: 0.35...0.85)
                ]
                
                let randomDurations = [
                    Double.random(in: 0.35...0.55),
                    Double.random(in: 0.3...0.5),
                    Double.random(in: 0.4...0.6),
                    Double.random(in: 0.35...0.55)
                ]
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: randomDurations[0])) {
                        bar1 = randomHeights[0]
                    }
                    withAnimation(.easeInOut(duration: randomDurations[1])) {
                        bar2 = randomHeights[1]
                    }
                    withAnimation(.easeInOut(duration: randomDurations[2])) {
                        bar3 = randomHeights[2]
                    }
                    withAnimation(.easeInOut(duration: randomDurations[3])) {
                        bar4 = randomHeights[3]
                    }
                }
                
                try? await Task.sleep(for: .milliseconds(Int.random(in: 250...450)))
            }
        }
    }
    
    private func stopAnimating() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            bar1 = 0.0
            bar2 = 0.0
            bar3 = 0.0
            bar4 = 0.0
        }
    }
    
    private func BarShape(height: CGFloat, isPlaying: Bool) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        Color.white.opacity(0.88)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(
                width: barWidth,
                height: isPlaying ? max(dotSize, maxHeight * height) : dotSize
            )
    }
}






