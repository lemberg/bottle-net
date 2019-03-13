//
//  OSDefines.swift
//  YOLOv3-CoreML
//
//  Created by Sergiy Loza on 3/13/19.
//  Copyright © 2019 Lemberg Solutions. All rights reserved.
//
import Foundation

#if os(iOS)

import UIKit

public typealias Image = UIImage
public typealias Color = UIColor
public typealias Screen = UIScreen
public typealias Font = UIFont
public typealias BezierPath = UIBezierPath

public var screenScale: CGFloat {
    return UIScreen.main.scale
}

#elseif os(OSX)

import AppKit

public typealias Image = NSImage
public typealias Color = NSColor
public typealias Screen = NSScreen
public typealias Font = NSFont
public typealias BezierPath = NSBezierPath

public var screenScale: CGFloat {
    return NSScreen.main?.backingScaleFactor ?? 1.0
}

public extension NSBezierPath {
    
    var cgPath: CGPath {
        get {
            let path = CGMutablePath()
            let points = NSPointArray.allocate(capacity: 3)
            for i in 0 ..< self.elementCount {
                let type = self.element(at: i, associatedPoints: points)
                switch type {
                case .moveTo:
                    path.move(to: points[0])
                case .lineTo:
                    path.addLine(to: points[0])
                case .curveTo:
                    path.addCurve(to: points[2], control1: points[0], control2: points[1])
                case .closePath:
                    path.closeSubpath()
                }
            }
            return path
        }
    }
    
    public func addLine(to point: NSPoint) {
        self.line(to: point)
    }
    
    public func addCurve(to point: NSPoint, controlPoint1: NSPoint, controlPoint2: NSPoint) {
        self.curve(to: point, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
    }
    
    public func addQuadCurve(to point: NSPoint, controlPoint: NSPoint) {
        self.curve(to: point,
                   controlPoint1: NSPoint(
                    x: (controlPoint.x - self.currentPoint.x) * (2.0 / 3.0) + self.currentPoint.x,
                    y: (controlPoint.y - self.currentPoint.y) * (2.0 / 3.0) + self.currentPoint.y),
                   controlPoint2: NSPoint(
                    x: (controlPoint.x - point.x) * (2.0 / 3.0) +  point.x,
                    y: (controlPoint.y - point.y) * (2.0 / 3.0) +  point.y))
    }
}


#endif


