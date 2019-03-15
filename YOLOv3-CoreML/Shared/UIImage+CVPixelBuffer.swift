
import Foundation

#if os(iOS)

import UIKit

#elseif os(OSX)

import AppKit

#endif

extension Image {
    
  public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
    var maybePixelBuffer: CVPixelBuffer?
    let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                 kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
    let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                     Int(width),
                                     Int(height),
                                     kCVPixelFormatType_32ARGB,
                                     attrs as CFDictionary,
                                     &maybePixelBuffer)

    guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
      return nil
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

    guard let context = CGContext(data: pixelData,
                                  width: Int(width),
                                  height: Int(height),
                                  bitsPerComponent: 8,
                                  bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
    else {
      return nil
    }

    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)

    #if os(iOS)
    
    UIGraphicsPushContext(context)
    
    #elseif os(OSX)
    
    NSGraphicsContext.saveGraphicsState()
    let c = NSGraphicsContext(cgContext: context, flipped: true)
    NSGraphicsContext.current = c
    
    #endif
    
    self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))

    #if os(iOS)

    UIGraphicsPopContext()

    #elseif os(OSX)

    NSGraphicsContext.restoreGraphicsState()
    
    #endif
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

    return pixelBuffer
  }
}

#if os(iOS)

#elseif os(OSX)

extension Image {
    
    func cutArea(at frame: CGRect) -> Image? {
        
        var rect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        guard let cgRef = cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return nil }
        guard let crop = cgRef.cropping(to: frame) else { return nil }
        let result = NSImage(cgImage: crop, size: frame.size)
        return result
    }
    
    var bitmapRep: NSBitmapImageRep? {
        var rect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        guard let cgRef = cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return nil }
        let rep = NSBitmapImageRep(cgImage: cgRef)
        return rep
    }
    
    var jpegRepresentation: Data? {
        self.lockFocus()
        guard let rep = self.bitmapRep,
            let data = rep.representation(using: .jpeg, properties: [:]) else {
                self.unlockFocus()
                return nil
        }
        
        self.unlockFocus()
        return data
    }
    
    func scaled(to size: NSSize, using context: CIContext = CIContext()) -> Image? {
        guard let pixelBuffer = self.pixelBuffer(width: Int(size.width), height: Int(size.height)) else { return nil }

        let image = CIImage(cvPixelBuffer: pixelBuffer)
        
        guard let cgImage = context.createCGImage(image, from: CGRect(origin: CGPoint.zero, size: size)) else { return nil }
        return NSImage(cgImage: cgImage, size: size)
    }
}

#endif
