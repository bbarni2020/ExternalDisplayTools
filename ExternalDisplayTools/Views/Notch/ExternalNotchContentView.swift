import SwiftUI

struct ExternalNotchContentView: View {
    let request: ExternalNotchRequest

    private let indicatorSize: CGFloat = 28

    var body: some View {
        HStack(spacing: 12) {
            leftView(request.left)
                .frame(width: indicatorSize, height: indicatorSize)

            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .clipped()

            rightView(request.right)
                .frame(width: indicatorSize, height: indicatorSize)
        }
    }

    @ViewBuilder
    private func leftView(_ content: ExternalNotchLeftContent?) -> some View {
        if let content {
            switch content {
            case .appBundleId(let bundleId):
                if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: appUrl.path))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Color.clear
                }
            }
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private func rightView(_ content: ExternalNotchRightContent?) -> some View {
        if let content {
            switch content {
            case .text(let value):
                Text(value)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.trailing)
                    .truncationMode(.tail)
            case .icon(let name):
                Image(systemName: name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            case .image(let url):
                ExternalNotchRemoteImage(url: url, isAnimated: false)
            case .gif(let url):
                ExternalNotchRemoteImage(url: url, isAnimated: true)
            }
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch request.content {
        case .text(let value):
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)
        case .image(let url):
            ExternalNotchRemoteImage(url: url, isAnimated: false)
        case .gif(let url):
            ExternalNotchRemoteImage(url: url, isAnimated: true)
        }
    }
}

struct ExternalNotchRemoteImage: View {
    let url: URL
    let isAnimated: Bool

    @State private var imageData: Data?

    var body: some View {
        Group {
            if let imageData, let image = NSImage(data: imageData) {
                if isAnimated {
                    ExternalNotchAnimatedImage(nsImage: image)
                } else {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            load()
        }
    }

    private func load() {
        if url.isFileURL {
            if let data = try? Data(contentsOf: url) {
                imageData = data
            }
            return
        }

        Task { @MainActor in
            if let (data, _) = try? await URLSession.shared.data(from: url) {
                imageData = data
            }
        }
    }
}

struct ExternalNotchAnimatedImage: NSViewRepresentable {
    let nsImage: NSImage

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = true
        imageView.image = nsImage
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        if nsView.image != nsImage {
            nsView.image = nsImage
        }
    }
}
