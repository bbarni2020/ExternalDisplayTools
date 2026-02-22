import SwiftUI

struct HelloAnimation: View {
    @State private var scale: CGFloat = 0.92
    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = 6
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 48))
                .foregroundColor(.white)
            
            Text("Hello")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .offset(y: yOffset)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                scale = 1.0
                opacity = 1.0
                yOffset = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.24)) {
                    opacity = 0
                    yOffset = -4
                }
            }
        }
    }
}

struct DropAnimation: View {
    let icon: String
    @State private var offset: CGFloat = -24
    @State private var opacity: Double = 0
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 32))
            .foregroundColor(.white)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                    offset = 0
                    opacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeIn(duration: 0.22)) {
                        offset = -6
                        opacity = 0
                    }
                }
            }
    }
}

struct BluetoothConnectionAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 40, height: 40)
                    .scaleEffect(isAnimating ? 1.6 : 0.85)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: 1.4)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.24),
                        value: isAnimating
                    )
            }
            
            Image(systemName: "bluetooth")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .scaleEffect(isAnimating ? 1.02 : 0.98)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct ChargingAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Image(systemName: "bolt.fill")
                .font(.system(size: 32))
                .foregroundColor(.yellow)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.6)
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 0.9)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

struct IncomingCallAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.green.opacity(0.5), lineWidth: 2)
                .frame(width: 50, height: 50)
                .scaleEffect(isAnimating ? 1.42 : 1.0)
                .opacity(isAnimating ? 0 : 1)
                .animation(
                    Animation.easeOut(duration: 1.2)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            Image(systemName: "phone.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
                .scaleEffect(isAnimating ? 1.08 : 0.94)
                .rotationEffect(.degrees(isAnimating ? 4 : -4))
                .animation(
                    Animation.easeInOut(duration: 0.85)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct LowBatteryAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "battery.0")
                .font(.system(size: 16))
                .foregroundColor(.orange)
            
            Text("Low Battery")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.orange)
        }
        .padding(.horizontal)
        .opacity(isAnimating ? 1.0 : 0.5)
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}
