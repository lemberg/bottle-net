
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


extension Image {
    
    func cutArea(at frame: CGRect) -> Image? {
        
//        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
//                                   pixelsWide: Int(frame.width),
//                                   pixelsHigh: Int(frame.height),
//                                   bitsPerSample: 8,
//                                   samplesPerPixel: 4,
//                                   hasAlpha: true,
//                                   isPlanar: false,
//                                   colorSpaceName: .deviceRGB,
//                                   bitmapFormat: .alphaFirst,
//                                   bytesPerRow: 0,
//                                   bitsPerPixel: 0) else { return nil }
//        guard let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
//
//        NSGraphicsContext.saveGraphicsState()
//        NSGraphicsContext.current = context
//
//        let cgContext = context.cgContext
//
//        cgContext.translateBy(x: 0, y: CGFloat(size.height))
//        cgContext.scaleBy(x: 1, y: -1)
//
//        self.draw(in: NSRect(x: frame.origin.x, y: frame.origin.y, width: size.width, height: size.height))
//
//        NSGraphicsContext.restoreGraphicsState()
//
//        let result = NSImage(size: NSSize(width: frame.width, height: frame.height))
//        result.addRepresentation(rep)
        
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
}
