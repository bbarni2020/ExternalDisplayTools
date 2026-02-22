import SwiftUI
import SkyLightWindow

struct ContentView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
                .allowsHitTesting(false)

            NotchView()
                .allowsHitTesting(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .moveToSky()
    }
}

#Preview {
    ContentView()
}
