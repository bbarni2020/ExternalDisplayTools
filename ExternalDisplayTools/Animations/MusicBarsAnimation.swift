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
    private let idleHeight: CGFloat = 0.22
    
    var body: some View {
        HStack(alignment: .center, spacing: barSpacing) {
            BarShape(height: bar1, isPlaying: isPlaying)
            BarShape(height: bar2, isPlaying: isPlaying)
            BarShape(height: bar3, isPlaying: isPlaying)
            BarShape(height: bar4, isPlaying: isPlaying)
        }
        .scaleEffect(isPlaying ? 1.0 : 0.92)
        .opacity(isPlaying ? 1.0 : 0.75)
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
        .onAppear {
            if isPlaying && !reduceMotion {
                startAnimating()
            } else {
                stopAnimating()
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    bar1 = isPlaying ? 0.72 : idleHeight
                    bar2 = isPlaying ? 0.48 : idleHeight
                    bar3 = isPlaying ? 0.86 : idleHeight
                    bar4 = isPlaying ? 0.56 : idleHeight
                }
            } else if isPlaying {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }
    
    private func startAnimating() {
        animationTask?.cancel()

        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            bar1 = 0.55
            bar2 = 0.43
            bar3 = 0.64
            bar4 = 0.5
        }

        animationTask = Task {
            while !Task.isCancelled {
                let randomHeights = [
                    CGFloat.random(in: 0.38...0.88),
                    CGFloat.random(in: 0.3...0.82),
                    CGFloat.random(in: 0.46...0.94),
                    CGFloat.random(in: 0.34...0.8)
                ]
                
                await MainActor.run {
                    let pulse = Animation.spring(response: 0.3, dampingFraction: 0.82, blendDuration: 0.06)

                    withAnimation(pulse.speed(0.98)) {
                        bar1 = randomHeights[0]
                    }
                    withAnimation(pulse.speed(1.06)) {
                        bar2 = randomHeights[1]
                    }
                    withAnimation(pulse.speed(0.93)) {
                        bar3 = randomHeights[2]
                    }
                    withAnimation(pulse.speed(1.02)) {
                        bar4 = randomHeights[3]
                    }
                }
                
                try? await Task.sleep(for: .milliseconds(Int.random(in: 210...320)))
            }
        }
    }
    
    private func stopAnimating() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            bar1 = idleHeight
            bar2 = idleHeight
            bar3 = idleHeight
            bar4 = idleHeight
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
                height: max(dotSize, maxHeight * height)
            )
    }
}






