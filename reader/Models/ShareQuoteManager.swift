import SwiftUI
import AppKit

@MainActor
class ShareQuoteManager {
    static func parseQuote(_ quoteString: String) -> (quote: String, attribution: String?) {
        let components = quoteString.components(separatedBy: " — ")
        
        if components.count > 1 {
            let attributionText = components[1]
            
            let quoteParts = components[0].components(separatedBy: " [p. ")
            let quoteText = quoteParts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            
            return (quoteText, attributionText)
        } else {
            let quoteParts = quoteString.components(separatedBy: " [p. ")
            let quoteText = quoteParts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            
            return (quoteText, nil)
        }
    }
    
    static func exportQuoteAsPNG(
        exportView: some View,
        size: CGSize,
        cornerRadius: CGFloat,
        filename: String,
        scaleFactor: CGFloat = 2.0
    ) {
        let hostingView = NSHostingView(rootView: exportView)
        
        hostingView.frame = CGRect(origin: .zero, size: size)
        
        hostingView.setFrameSize(size)
        hostingView.needsLayout = true
        hostingView.layoutSubtreeIfNeeded()
        
        let tempWindow = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        tempWindow.contentView = NSView(frame: NSRect(origin: .zero, size: size))
        tempWindow.contentView?.addSubview(hostingView)
        
        tempWindow.alphaValue = 0
        tempWindow.orderFront(nil)
        
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        
        let scaledSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        guard let image = renderViewToImage(
            hostingView: hostingView,
            size: size,
            scaledSize: scaledSize,
            scaleFactor: scaleFactor
        ) else {
            print("Failed to create image")
            hostingView.removeFromSuperview()
            return
        }
        
        guard let roundedImage = applyRoundedCorners(
            to: image,
            cornerRadius: cornerRadius * scaleFactor
        ) else {
            print("Failed to apply rounded corners")
            hostingView.removeFromSuperview()
            return
        }
        
        guard let pngData = convertToPNGData(from: roundedImage) else {
            print("Failed to convert to PNG")
            hostingView.removeFromSuperview()
            return
        }
        
        hostingView.removeFromSuperview()
        
        showSaveDialog(pngData: pngData, filename: filename)
    }
    
    private static func renderViewToImage(
        hostingView: NSHostingView<some View>,
        size: CGSize,
        scaledSize: CGSize,
        scaleFactor: CGFloat
    ) -> NSImage? {
        let image = NSImage(size: scaledSize)
        
        image.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        
        guard let cgContext = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }
        
        cgContext.saveGState()
        
        cgContext.scaleBy(x: scaleFactor, y: scaleFactor)
        
        cgContext.translateBy(x: 0, y: size.height)
        cgContext.scaleBy(x: 1, y: -1)
        
        hostingView.layer?.render(in: cgContext)
        
        cgContext.restoreGState()
        
        image.unlockFocus()
        
        return image
    }
    
    private static func applyRoundedCorners(to image: NSImage, cornerRadius: CGFloat) -> NSImage? {
        let size = image.size
        let rect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        path.addClip()
        
        image.draw(in: rect)
        
        newImage.unlockFocus()
        return newImage
    }
    
    private static func convertToPNGData(from image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmap.representation(
            using: .png,
            properties: [NSBitmapImageRep.PropertyKey.compressionFactor: 1.0]
        )
    }
    
    private static func showSaveDialog(pngData: Data, filename: String) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = filename
        
        savePanel.beginSheetModal(for: NSApplication.shared.keyWindow!) { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try pngData.write(to: url)
                } catch {
                    print("Error saving PNG: \(error)")
                }
            }
        }
    }
}
