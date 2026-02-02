import Cocoa

final class DoomDockRenderer {
    private let dockTile: NSDockTile
    private let imageView: NSImageView
    private let stateQueue = DispatchQueue(label: "DoomDockRendererState")
    private var pendingFrame: Data?
    private var pendingSize: CGSize = .zero
    private var updateScheduled = false

    init?(dockTile: NSDockTile = NSApp.dockTile) {
        self.dockTile = dockTile
        imageView = NSImageView(frame: .zero)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        dockTile.contentView = imageView
        dockTile.display()
    }

    func update(with data: Data, size: CGSize) {
        stateQueue.sync {
            pendingFrame = data
            pendingSize = size
            guard !updateScheduled else { return }
            updateScheduled = true
            DispatchQueue.main.async { [weak self] in
                self?.flushPendingFrame()
            }
        }
    }

    private func flushPendingFrame() {
        var frameData: Data?
        var frameSize: CGSize = .zero
        stateQueue.sync {
            frameData = pendingFrame
            frameSize = pendingSize
            pendingFrame = nil
            updateScheduled = false
        }
        guard let frameData else { return }
        updateDockTile(with: frameData, size: frameSize)
    }

    private func updateDockTile(with data: Data, size: CGSize) {
        let width = Int(size.width)
        let height = Int(size.height)
        guard width > 0, height > 0 else { return }

        let bytesPerRow = width * 4
        guard let provider = CGDataProvider(data: data as CFData) else { return }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(
            CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        )

        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else { return }

        let image = NSImage(cgImage: cgImage, size: dockTile.size)
        imageView.image = image
        dockTile.display()
    }
}
