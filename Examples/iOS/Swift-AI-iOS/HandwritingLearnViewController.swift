//
//  HandwritingLearnViewController.swift
//  Swift-AI-iOS
//
//  Created by Collin Hundley on 12/18/15.
//  Copyright © 2015 Appsidian. All rights reserved.
//

import UIKit

class HandwritingLearnViewController: UIViewController {
    
    var network: FFNN!
    
    let handwritingLearnView = HandwritingLearnView()
    
    override func loadView() {
        self.view = self.handwritingLearnView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = Bundle.main.url(forResource: "handwriting-learn-ffnn", withExtension: nil)!
        self.network = FFNN.fromFile(url)
        
        self.handwritingLearnView.textField.delegate = self
        self.handwritingLearnView.textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.handwritingLearnView.textField.keyboardType = .numberPad
        self.handwritingLearnView.textField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.handwritingLearnView.textField.resignFirstResponder()
    }
    
}

// MARK: Neural network and drawing methods

extension HandwritingLearnViewController {
    
    fileprivate func generateCharacter(_ digit: Int) {
        guard let inputArray = self.digitToArray(digit) else {
            print("Error: Invalid digit: \(digit)")
            return
        }
        do {
            let output = try self.network.update(inputs: inputArray)
            let image = self.pixelsToImage(output)
            self.handwritingLearnView.canvas.image = image
        } catch {
            print(error)
        }
    }
    
    struct PixelData {
        var a: UInt8 = 0
        var r: UInt8 = 0
        var g: UInt8 = 0
        var b: UInt8 = 0
    }
    
    func pixelsToImage(_ pixels: [Float]) -> UIImage? {
        let width = 28, height = 28
        
        assert(width > 0)
        
        assert(height > 0)
        
        var pixelsArray = [PixelData]()
        for pixelFloat in pixels {
            pixelsArray.append(PixelData(a: UInt8(pixelFloat * 255), r: 0, g: 0, b: 0))
        }
        
        let pixelDataSize = MemoryLayout<PixelData>.size
        assert(pixelDataSize == 4)
        
        assert(pixelsArray.count == Int(width * height))
        
        let data: Data = pixelsArray.withUnsafeBufferPointer {
            return Data(buffer: $0)
        }
        
        let cfdata = NSData(data: data) as CFData
        let provider: CGDataProvider! = CGDataProvider(data: cfdata)
        if provider == nil {
            print("CGDataProvider is not supposed to be nil")
            return nil
        }
        let cgimage: CGImage! = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * pixelDataSize,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
        if cgimage == nil {
            print("CGImage is not supposed to be nil")
            return nil
        }
        return UIImage(cgImage: cgimage)
    }
//    fileprivate func pixelsToImage(_ pixelFloats: [Float]) -> UIImage? {
//        guard pixelFloats.count == 784 else {
//            print("Error: Invalid number of pixels given: \(pixelFloats.count). Expected: 784")
//            return nil
//        }
//        struct PixelData {
//            let a: UInt8
//            let r: UInt8
//            let g: UInt8
//            let b: UInt8
//        }
//        var pixels = [PixelData]()
//        for pixelFloat in pixelFloats {
//            pixels.append(PixelData(a: UInt8(pixelFloat * 255), r: 0, g: 0, b: 0))
//        }
//        
//        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
//        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
//        var data = pixels
//        
//        var pointer = UnsafeMutableBufferPointer(start: &data, count: data.count * MemoryLayout<PixelData>.size)
//        
//        var dataFromPointer = Data.init(buffer: pointer)
//        
//        let dataValue = NSData(bytes: &dataFromPointer, length: MemoryLayout<sockaddr_in>.size) as CFData
//        
//            //CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(data.bytes), data.length)
//
//        
//        let providerRef = CGDataProvider(data: dataValue)
//        let cgim = CGImage(width: 28, height: 28, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 28 * MemoryLayout<PixelData>.size, space: rgbColorSpace, bitmapInfo: bitmapInfo, provider: providerRef!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
//        return UIImage.init(cgImage: cgim!)
//    }
//    
    
    fileprivate func digitToArray(_ digit: Int) -> [Float]? {
        guard digit >= 0 && digit <= 9 else {
            return nil
        }
        var array = [Float](repeating: 0, count: 10)
        array[digit] = 1
        return array
    }
    
}



extension HandwritingLearnViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.handwritingLearnView.textField.text = ""
        return true
    }
    
    func textChanged(_ sender: UITextField) {
        if let digit = Int(self.handwritingLearnView.textField.text!) {
            self.generateCharacter(digit)
        }
        self.handwritingLearnView.textField.resignFirstResponder()
    }
    
}

extension UnsafeMutablePointer {
    init(_ from : UnsafeMutablePointer) {
        // Swift 2: init(_ from : UnsafeMutablePointer<Memory>) {
        self = from
    }
}
