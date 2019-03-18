//
//  ViewController.swift
//  ModelImageCropper
//
//  Created by Sergiy Loza on 3/13/19.
//  Copyright © 2019 Lemberg Solutions. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var savesCount: NSTextField!
    @IBOutlet weak var processCount: NSTextField!
    @IBOutlet weak var rotateCheckBox: NSButton!
    @IBOutlet weak var mirrorCheckBox: NSButton!
    @IBOutlet weak var blurCheckBox: NSButton!
    @IBOutlet weak var reduceNoiseCheckBox: NSButton!
    
    let bottleDetector = DetectObjects()
    
    private let saveQueue: OperationQueue = {
        let value = OperationQueue()
        value.name = "com.file.save"
        value.qualityOfService = .userInteractive
        return value
    }()
    
    private let cropQueueQueue: OperationQueue = {
        let value = OperationQueue()
        value.name = "com.file.crop"
        value.qualityOfService = .userInteractive
        return value
    }()
    
    
    private let loadQueue: OperationQueue = {
        let value = OperationQueue()
        value.name = "com.file.load"
        value.qualityOfService = .utility
        return value
    }()
    
    let context = CIContext()
    
    var imagesToCrop = 0 {
        didSet {
            updateUI()
        }
    }
    var croppedImages = 0 {
        didSet {
            updateUI()
        }
    }
    
    func updateUI() {
        
        let update = {
            let title = "\(self.croppedImages) / \(self.imagesToCrop)"
            self.statusLabel.stringValue = title
            self.savesCount.stringValue = "\(self.saveQueue.operationCount)"
            self.processCount.stringValue = "\(self.cropQueueQueue.operationCount)"
        }
        
        if Thread.current == Thread.main {
            update()
        } else {
            DispatchQueue.main.async {
                update()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func selectFiles(_ sender: Any) {
        
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose images";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = true;
        dialog.allowedFileTypes        = ["jpg", "png"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            DispatchQueue.main.async {
                guard let result = dialog.urls.first else {
                    return
                }
                self.cropImagesInFolder(at: result)
            }
        } else {
            return
        }
    }
    
    var fm = FileManager.default
    
    func cropImagesInFolder(at url: URL) {
        
        self.imagesToCrop = 0
        self.croppedImages = 0
        
        typealias Pair = (URL, String)
        var pairs:[Pair] = []
        
        let resultFolder = url.appendingPathComponent("Result")
        
        cleanupDirectory(at: resultFolder)
        
        try? fm.contentsOfDirectory(atPath: url.path).forEach { (value) in
            if value == ".DS_Store" {
                return
            }
            pairs.append((url, value))
        }
        
        createDirectory(at: resultFolder)
        
        pairs.forEach { pair in
            self.cropImages(at: pair.0, folderName: pair.1)
        }
    }
    
    func cropImages(at url: URL, folderName: String) {
        
        let imagesFolder = url.appendingPathComponent(folderName)
        let enumerator = fm.enumerator(at: imagesFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]) { (errorUrl, error) -> Bool in
            return true
        }
        
        let count = fm.enumerator(at: imagesFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]) { (errorUrl, error) -> Bool in
            return true
        }
        
        self.imagesToCrop += count?.allObjects.count ?? 0
        
        let resultsFolder = imagesFolder.deletingLastPathComponent().appendingPathComponent("Result/\(folderName)")
        cleanupDirectory(at: resultsFolder)
        createDirectory(at: resultsFolder)
        
        while let imagePath = enumerator?.nextObject() as? URL {
            
            loadQueue.addOperation {
                autoreleasepool {
                    let imageName = imagePath.deletingPathExtension().lastPathComponent
                    let imageExt = imagePath.pathExtension
                    guard let image = self.loadImage(fromFileAt: imagePath) else { return }
                    print("Image loaded from \(imagePath.path)")
                    self.cropQueueQueue.addOperation {
                        print("Start process image from \(imagePath.path)")
                        let bottleImages = self.cropBottles(from: image)
                        for (index, image) in bottleImages.enumerated() {
                            var resultName = "\(imageName)_cropped_\(index).\(imageExt)"
                            var resultPath = resultsFolder.appendingPathComponent(resultName)
                            self.saveBottleImage(image, at: resultPath)
                            
                            if self.rotateCheckBox.state == .on {
                                for i in 1..<4 {
                                    let degree: CGFloat = CGFloat(90) * CGFloat(i)
                                    if let resultImage = image.rotated(for: degree, using: self.context) {
                                        resultName = "\(imageName)_cropped_rotated_\(degree)_\(index).\(imageExt)"
                                        resultPath = resultsFolder.appendingPathComponent(resultName)
                                        self.saveBottleImage(resultImage, at: resultPath)
                                    }
                                }
                            }
                            
                            if self.mirrorCheckBox.state == .on {
                                if let resultImage = image.mirored(context: self.context) {
                                    resultName = "\(imageName)_cropped_mirrored_\(index).\(imageExt)"
                                    resultPath = resultsFolder.appendingPathComponent(resultName)
                                    self.saveBottleImage(resultImage, at: resultPath)
                                }
                            }
                            
                            if self.blurCheckBox.state == .on {
                                if let resultImage = image.gaussianBlurred(context: self.context) {
                                    resultName = "\(imageName)_cropped_blurred_\(index).\(imageExt)"
                                    resultPath = resultsFolder.appendingPathComponent(resultName)
                                    self.saveBottleImage(resultImage, at: resultPath)
                                }
                            }
                            
                            if self.reduceNoiseCheckBox.state == .on {
                                if let resultImage = image.noiseReduced(context: self.context) {
                                    resultName = "\(imageName)_cropped_reduced_noise_\(index).\(imageExt)"
                                    resultPath = resultsFolder.appendingPathComponent(resultName)
                                    self.saveBottleImage(resultImage, at: resultPath)
                                }
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
    private func loadImage(fromFileAt url: URL) -> Image? {
        guard let image = Image(contentsOf: url) else {
            print("Could not load image at \(url.path)")
            return nil
        }
        return image
    }
    
    private func cropBottles(from image: Image) -> [Image] {
        
        guard let buffer = image.pixelBuffer(width: Int(image.size.width), height: Int(image.size.height)), let resizedBuffer = resizePixelBuffer(buffer, width: YOLO.inputWidth, height: YOLO.inputHeight) else {
            print("Could not create pixel for image \(image)")
            return []
        }
        
        guard let frames = bottleDetector.predict(resizedBuffer) else {
            print("Frames not found on image \(image)")
            return []
        }
        
        
        return frames.map { $0.rect }.compactMap { (rect) in
            let x = max(0, Int(floor(rect.origin.x)))
            let y = max(0, Int(floor(rect.origin.y)))
            var w = Int(floor(rect.width))
            var h = Int(floor(rect.height))
            
            if x + w > YOLO.inputWidth {
                let diff = (x + w) - YOLO.inputWidth
                w = w - diff
            }
            
            if y + h > YOLO.inputWidth {
                let diff = (y + h) - YOLO.inputHeight
                h = h - diff
            }
            guard let cropped = resizePixelBuffer(resizedBuffer, cropX: x, cropY: y, cropWidth: w, cropHeight: h, scaleWidth: Resnet.inputWidth, scaleHeight: Resnet.inputHeight) else { return nil }
            let ciimage = CIImage(cvImageBuffer: cropped)
            let nsingerep = NSCIImageRep(ciImage: ciimage)
            let nsimage = NSImage(size: NSSize(width: Resnet.inputWidth, height: Resnet.inputHeight))
            nsimage.addRepresentation(nsingerep)
            return nsimage
        }
    }
    
    func cleanupDirectory(at url: URL) {
        do {
            if fm.fileExists(atPath: url.path) {
                try fm.removeItem(at: url)
            }
        } catch let error {
            print("Error on clean \(error)")
        }
    }
    
    func createDirectory(at url: URL) {
        do {
            if fm.fileExists(atPath: url.path) {
                try fm.removeItem(at: url)
            }
            try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            print("Error on clean \(error)")
        }
    }
    
    func saveBottleImage(_ image: Image, at url: URL) {
        print("Image is ready to save at \(url.path)")
        updateUI()
        saveQueue.addOperation {
            if let data = image.jpegRepresentation {
                if self.fm.createFile(atPath: url.path, contents: data, attributes: nil) {
                    print("Image saved to \(url.path)")
                    self.croppedImages += 1
                }
            }
        }
    }
    
    func bottleFrameFrom(originalFrame: CGRect, bottleFrame: CGRect) -> CGRect {
        
        let yoloRect: CGRect = CGRect(x: 0, y: 0, width: CGFloat(YOLO.inputWidth), height: CGFloat(YOLO.inputHeight))
        
        let x = (bottleFrame.minX / yoloRect.maxX) * originalFrame.maxX
        let y = (bottleFrame.minY / yoloRect.maxY) * originalFrame.maxY
        let w = (bottleFrame.width / yoloRect.width) * originalFrame.width
        let h = (bottleFrame.height / yoloRect.height) * originalFrame.height
        return CGRect(x: x, y: y, width: w, height: h)
    }
}

