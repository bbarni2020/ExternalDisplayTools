import SwiftUI

struct HelloAnimation: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 48))
                .foregroundColor(.white)
            
            Text("Hello")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                }
            }
        }
    }
}

struct DropAnimation: View {
    let icon: String
    @State private var offset: CGFloat = -50
    @State private var opacity: Double = 0
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 32))
            .foregroundColor(.white)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    offset = 0
                    opacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
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
                    .stroke(Color.blue.opacity(0.4), lineWidth: 2)
                    .frame(width: 40, height: 40)
                    .scaleEffect(isAnimating ? 2.0 : 0.5)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                        value: isAnimating
                    )
            }
            
            Image(systemName: "bluetooth")
                .font(.system(size: 20))
                .foregroundColor(.blue)
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
                Animation.easeInOut(duration: 0.8)
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
                .scaleEffect(isAnimating ? 1.5 : 1.0)
                .opacity(isAnimating ? 0 : 1)
                .animation(
                    Animation.easeOut(duration: 1.0)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            Image(systemName: "phone.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .animation(
                    Animation.easeInOut(duration: 0.8)
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
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}
