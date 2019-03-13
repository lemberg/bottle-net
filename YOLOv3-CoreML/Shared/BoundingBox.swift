import Foundation

#if os(iOS)

import UIKit

#elseif os(OSX)

import AppKit

#endif

class BoundingBox {
  let shapeLayer: CAShapeLayer
  let textLayer: CATextLayer

  init() {
    
    shapeLayer = CAShapeLayer()
    shapeLayer.fillColor = Color.clear.cgColor
    shapeLayer.lineWidth = 4
    shapeLayer.isHidden = true

    textLayer = CATextLayer()
    textLayer.foregroundColor = Color.black.cgColor
    textLayer.isHidden = true
    textLayer.contentsScale = screenScale
    textLayer.fontSize = 14
    textLayer.font = Font(name: "Avenir", size: textLayer.fontSize)
    textLayer.alignmentMode = CATextLayerAlignmentMode.center
  }

  func addToLayer(_ parent: CALayer) {
    parent.addSublayer(shapeLayer)
    parent.addSublayer(textLayer)
  }

  func show(frame: CGRect, label: String, color: Color) {
    CATransaction.setDisableActions(true)

    let path = BezierPath(rect: frame)
    shapeLayer.path = path.cgPath
    shapeLayer.strokeColor = color.cgColor
    shapeLayer.isHidden = false

    textLayer.string = label
    textLayer.backgroundColor = color.cgColor
    textLayer.isHidden = false

    let attributes = [
      NSAttributedString.Key.font: textLayer.font as Any
    ]

    let textRect = label.boundingRect(with: CGSize(width: 400, height: 100),
                                      options: .truncatesLastVisibleLine,
                                      attributes: attributes, context: nil)
    let textSize = CGSize(width: textRect.width + 12, height: textRect.height)
    let textOrigin = CGPoint(x: frame.origin.x - 2, y: frame.origin.y - textSize.height)
    textLayer.frame = CGRect(origin: textOrigin, size: textSize)
  }

  func hide() {
    shapeLayer.isHidden = true
    textLayer.isHidden = true
  }
}
