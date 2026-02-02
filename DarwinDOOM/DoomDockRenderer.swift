import Cocoa

final class DoomDockRenderer {
    private let dockTile: NSDockTile
    private let imageView: NSImageView
    private let stateQueue = DispatchQueue(label: "DoomDockRendererState")
    private var pendingFrame: Data?
    private var pendingSize: CGSize = .zero
    private var updateScheduled = false
    private var isEnabled = false

    init?(dockTile: NSDockTile = NSApp.dockTile) {
        self.dockTile = dockTile
        imageView = NSImageView(frame: .zero)
        imageView.imageScaling = .scaleProportionallyUpOrDown
    }

    func setEnabled(_ enabled: Bool) {
        stateQueue.sync {
            isEnabled = enabled
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if enabled {
                if self.dockTile.contentView !== self.imageView {
                    self.dockTile.contentView = self.imageView
                }
            } else {
                self.dockTile.contentView = nil
            }
            self.dockTile.display()
        }
    }

    func update(with data: Data, size: CGSize) {
        let shouldRender = stateQueue.sync { isEnabled }
        guard shouldRender else { return }
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

        let dockSize = dockTile.size
        let image = NSImage(size: dockSize)
        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: dockSize).fill()
        NSGraphicsContext.current?.imageInterpolation = .none
        let targetAspect = CGFloat(640.0 / 400.0)
        let dockAspect = dockSize.width / max(dockSize.height, 1.0)
        let drawRect: NSRect
        if dockAspect >= targetAspect {
            let height = dockSize.height
            let width = height * targetAspect
            drawRect = NSRect(x: (dockSize.width - width) * 0.5,
                              y: 0,
                              width: width,
                              height: height)
        } else {
            let width = dockSize.width
            let height = width / targetAspect
            drawRect = NSRect(x: 0,
                              y: (dockSize.height - height) * 0.5,
                              width: width,
                              height: height)
        }
        let cornerRadius = min(drawRect.width, drawRect.height) * 0.06
        let clipPath = NSBezierPath(roundedRect: drawRect,
                                    xRadius: cornerRadius,
                                    yRadius: cornerRadius)
        clipPath.addClip()
        NSImage(cgImage: cgImage, size: dockSize).draw(in: drawRect,
                                                       from: .zero,
                                                       operation: .sourceOver,
                                                       fraction: 1.0)
        image.unlockFocus()
        imageView.image = image
        dockTile.display()
    }
}
