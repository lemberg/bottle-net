//
//  DetectObjects.swift
//  YOLOv3-CoreML
//
//  Created by Sergiy Loza on 3/13/19.
//  Copyright © 2019 Lemberg Solutions. All rights reserved.
//

import AppKit
import Vision
import AVFoundation

class DetectObjects {
    
    let yolo = YOLO()
    var request: VNCoreMLRequest!
    var resizedPixelBuffer: CVPixelBuffer?
    let ciContext = CIContext()
    
    init() {
        setUpCoreImage()
        setupVision()
    }
    
    func setupVision() {
        guard let visionModel = try? VNCoreMLModel(for: yolo.model.model) else {
            print("Error: could not create Vision model")
            return
        }
        
        request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
        
        // NOTE: If you choose another crop/scale option, then you must also
        // change how the BoundingBox objects get scaled when they are drawn.
        // Currently they assume the full input image is used.
        request.imageCropAndScaleOption = .scaleFill
    }
    
    func setUpCoreImage() {
        let status = CVPixelBufferCreate(nil, YOLO.inputWidth, YOLO.inputHeight,
                                         kCVPixelFormatType_32BGRA, nil,
                                         &resizedPixelBuffer)
        if status != kCVReturnSuccess {
            print("Error: could not create resized pixel buffer", status)
        }
    }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let features = observations.first?.featureValue.multiArrayValue {
            let boundingBoxes = yolo.computeBoundingBoxes(features: [features, features, features])
            sendResult(boundingBoxes)
        }
    }
    
    func predict(_ image: Image) -> [YOLO.Prediction]? {
        
        if let buffer = image.pixelBuffer(width: YOLO.inputWidth, height: YOLO.inputHeight) {
            return predict(buffer)
        }
        
        return nil
    }
    
    func predict(_ pixelBuffer: CVPixelBuffer) -> [YOLO.Prediction]? {
        
        // Resize the input with Core Image to 416x416.
        guard let resizedPixelBuffer = resizedPixelBuffer else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let sx = CGFloat(YOLO.inputWidth) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let sy = CGFloat(YOLO.inputHeight) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let scaleTransform = CGAffineTransform(scaleX: sx, y: sy)
        let scaledImage = ciImage.transformed(by: scaleTransform)
        ciContext.render(scaledImage, to: resizedPixelBuffer)
        
        // This is an alternative way to resize the image (using vImage):
        //if let resizedPixelBuffer = resizePixelBuffer(pixelBuffer,
        //                                              width: YOLO.inputWidth,
        //                                              height: YOLO.inputHeight)
        
        // Resize the input to 416x416 and give it to our model.
        
        
        
        if let boundingBoxes = try? yolo.predict(image: resizedPixelBuffer), let index = labels.index(of: "bottle") {
            return boundingBoxes.filter({ (p) -> Bool in
                return p.classIndex == index
            })
        }
        return nil
    }
    
    func sendResult(_ boxes: [YOLO.Prediction]) {
        
    }
}
