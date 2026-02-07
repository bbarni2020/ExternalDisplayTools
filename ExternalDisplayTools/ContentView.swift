import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = NotchViewCoordinator.shared
    
    var body: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
            
            Canvas { context, size in
                let cornerSize: CGFloat = 12
                
                drawCorner(context: &context, position: .topLeft, cornerSize: cornerSize)
                drawCorner(context: &context, position: .topRight, cornerSize: cornerSize, size: size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            VStack(spacing: 0) {
                NotchView()
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer(minLength: 0)
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
    
    private func drawCorner(context: inout GraphicsContext, position: CornerPosition, cornerSize: CGFloat, size: CGSize = .zero) {
        var path = Path()
        
        switch position {
        case .topLeft:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: cornerSize, y: 0))
            path.addArc(center: CGPoint(x: cornerSize, y: cornerSize), radius: cornerSize, startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)
            path.addLine(to: CGPoint(x: 0, y: 0))
            
        case .topRight:
            let x = size.width
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: cornerSize))
            path.addArc(center: CGPoint(x: x - cornerSize, y: cornerSize), radius: cornerSize, startAngle: .degrees(0), endAngle: .degrees(270), clockwise: true)
            path.addLine(to: CGPoint(x: x, y: 0))
            
        case .bottomLeft:
            let y = size.height
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: 0, y: y - cornerSize))
            path.addArc(center: CGPoint(x: cornerSize, y: y - cornerSize), radius: cornerSize, startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
            path.addLine(to: CGPoint(x: 0, y: y))
            
        case .bottomRight:
            let x = size.width
            let y = size.height
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x - cornerSize, y: y))
            path.addArc(center: CGPoint(x: x - cornerSize, y: y - cornerSize), radius: cornerSize, startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        context.fill(
            path,
            with: .color(.black)
        )
    }
}

enum CornerPosition {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

#Preview {
    ContentView()
}
