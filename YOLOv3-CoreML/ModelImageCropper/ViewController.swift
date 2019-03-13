//
//  ViewController.swift
//  ModelImageCropper
//
//  Created by Sergiy Loza on 3/13/19.
//  Copyright © 2019 Lemberg Solutions. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    let bottleDetector = DetectObjects()
    
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
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = true;
        dialog.allowedFileTypes        = ["jpg", "png"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            DispatchQueue.main.async {
                let result = dialog.urls
                self.cleanupResultsDirectory()
                result.forEach { (url) in
                    self.cropBottles(fromFileAt: url)
                }
            }
        } else {
            return
        }
        
    }
    
    private func cropBottles(fromFileAt url: URL) {
        guard let image = Image(contentsOf: url) else {
            print("Could not load image at \(url.path)")
            return
        }
        
        guard let frames = bottleDetector.predict(image) else {
            return
        }
        
        frames.map { $0.rect }.forEach { (rect) in
            
            let originalFrame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            let realBottleFrame = bottleFrameFrom(originalFrame: originalFrame, bottleFrame: rect)
            guard let bottleImage = image.cutArea(at: realBottleFrame) else { return }
            DispatchQueue.global().async {
                self.saveBottleImage(bottleImage, name: url.lastPathComponent)
            }
        }
    }
    
    func cleanupResultsDirectory() {
        let fm = FileManager.default
        let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let downloadsDirectoryWithFolder = downloadsDirectory.appendingPathComponent("BottleImages")
        try? fm.removeItem(at: downloadsDirectoryWithFolder)
        try? fm.createDirectory(at: downloadsDirectoryWithFolder, withIntermediateDirectories: true, attributes: nil)
    }
    
    func saveBottleImage(_ image: Image, name: String) {
        let fm = FileManager.default
        let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let downloadsDirectoryWithFolder = downloadsDirectory.appendingPathComponent("BottleImages")
        let imagePath = downloadsDirectoryWithFolder.appendingPathComponent(name, isDirectory: false)

        image.lockFocus()
        guard let rep = image.bitmapRep,
            let data = rep.representation(using: .jpeg, properties: [:]) else {
                image.unlockFocus()
                return
        }
        
        image.unlockFocus()
        fm.createFile(atPath: imagePath.path, contents: data, attributes: nil)
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

