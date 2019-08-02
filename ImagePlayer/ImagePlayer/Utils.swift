//
//  Utils.swift
//  ImagePlayer
//
//  Created by Luis Reisewitz on 06.03.17.
//  Copyright © 2017 ZweiGraf. All rights reserved.
//

import UIKit
import CoreGraphics

struct Utils {}

// MARK: - 💾 Data Manipulation 💾
extension Utils {
    static func jpegData(for image: UIImage, quality: CGFloat = 0.8) -> Data {
        return UIImageJPEGRepresentation(image, 0.8)!
    }
    
    static func rawData(for image: UIImage) -> Data {
        let cgImage = image.cgImage!
        let width = cgImage.width
        let height = cgImage.height
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: CGBitmapInfo = cgImage.bitmapInfo
        let size = bytesPerRow * height
        
        // Initialize Pointer. Need to clean it up later ⚠️
        let intPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        
        let context = CGContext(data: intPointer, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let data = Data(bytes: intPointer, count: size)
        
        // Cleanup our Pointer 🚿
        intPointer.deinitialize()
        intPointer.deallocate()
        return data
    }
    
    static func data(for image: UIImage) -> Data {
        return rawData(for: image)
    }
}

// MARK: - 🗄 File Stuff 🗄
extension Utils {
    static func copy(image: UIImage, to location: URL) {
        let imageData = data(for: image)
        try! imageData.write(to: location)
    }
    
    static func cleanTempFolder() {
        _ = try? FileManager.default.contentsOfDirectory(at: URL.tempFolder, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions(rawValue: 0))
        .forEach { url in
            _ = try? FileManager.default.removeItem(at: url)
        }
    }
}

// MARK: - 🏛 Math Stuff 🏛
extension Utils {
    static func average(of numbers: [Int]) -> Int {
        return numbers.reduce(0, +) / numbers.count
    }
    
    static func averageLuminosity(of data: Data) -> UInt8 {
        // Initialize Pointer. Need to clean it up later ⚠️
        let intPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: intPointer, count: data.count)
        
        // Iterating through all data in 4-step, ignoring if there are any rest bytes
        let iterations = data.count / 4
        
        var currentAverage: Double = 0
        for iteration in 0...iterations {
            let r = (intPointer + iteration * 4 + 0).pointee
            let g = (intPointer + iteration * 4 + 1).pointee
            let b = (intPointer + iteration * 4 + 2).pointee

            // Ignoring alpha channel here, as it's constant
            
            // Standard RGB->Y conversion
            let newDatum: Double = 0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b)
            
            // For iterative average formula see http://www.heikohoffmann.de/htmlthesis/node134.html
            let calcIteration = iteration + 1
            let diff = newDatum - currentAverage
            currentAverage = currentAverage + ((1.0 / Double(calcIteration)) * diff)
        }
        
        intPointer.deinitialize()
        intPointer.deallocate(capacity: data.count)

        return UInt8(currentAverage)
    }
}

// MARK: - URL Extension
extension URL {
    init(temporaryURLWithFileExtension fileExtension: String) {
        let uptime = mach_absolute_time()
        let filename = "\(uptime).\(fileExtension)"
        let tmpFolderString = (NSTemporaryDirectory() as NSString).appendingPathComponent(filename)
        self.init(fileURLWithPath: tmpFolderString)
    }
    
    static var tempFolder: URL {
        let tmpFolderString = NSTemporaryDirectory()
        return URL(fileURLWithPath: tmpFolderString)
    }
}

// MARK: - DispatchQueue Extension
extension DispatchQueue {
    @nonobjc static var background: DispatchQueue = DispatchQueue.global(qos: .background)
}
