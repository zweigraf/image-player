//
//  Utils.swift
//  ImagePlayer
//
//  Created by Luis Reisewitz on 06.03.17.
//  Copyright © 2017 ZweiGraf. All rights reserved.
//

import UIKit
import AudioToolbox
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
        let size = bytesPerRow * height
        let intPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        let bitmapInfo: CGBitmapInfo = cgImage.bitmapInfo
        
        let context = CGContext(data: intPointer, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let data = Data(bytes: intPointer, count: size)
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
}

// MARK: - 🎵 Audio 🎵
extension Utils {
    static func writeWav(from image: UIImage, url: URL, sampleRate: Float64) {
        let imageData = data(for: image)
        writeWav(data: imageData, url: url, sampleRate: sampleRate)
    }
    
    static func writeWav(data: Data, url: URL, sampleRate: Float64) {
        writePCM(data: data, url: url, sampleRate: sampleRate, numberOfChannels: 2)
    }
    
    static func writePCM(data: Data, url: URL, sampleRate: Float64 = 44100, numberOfChannels: UInt32 = 2) {
        let formatID = kAudioFormatLinearPCM
        let formatFlags = AudioFormatFlags(kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked)
        
        let shortSize = UInt32(MemoryLayout<CShort>.stride)
        let bytesPerFrame = shortSize * numberOfChannels
        
        var streamDesc = AudioStreamBasicDescription(mSampleRate: sampleRate, mFormatID: formatID, mFormatFlags: formatFlags, mBytesPerPacket: bytesPerFrame, mFramesPerPacket: 1, mBytesPerFrame: bytesPerFrame, mChannelsPerFrame: numberOfChannels, mBitsPerChannel: shortSize * 8, mReserved: 0)
        
        var channelLayout = AudioChannelLayout()
        channelLayout.mChannelLayoutTag = numberOfChannels == 2 ? kAudioChannelLayoutTag_Stereo : kAudioChannelLayoutTag_Mono
        
        let cfUrl = url as CFURL
        let fileType = kAudioFileWAVEType
        var outputFile: ExtAudioFileRef?
        
        let result = ExtAudioFileCreateWithURL(cfUrl, fileType, &streamDesc, &channelLayout, 0, &outputFile)
        print("create result \(result)")
        
        let intPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: intPointer, count: data.count)
        
        let buffer = AudioBuffer(mNumberChannels: numberOfChannels, mDataByteSize: UInt32(data.count), mData: intPointer)
        var bufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: buffer)
        
        let numberOfFrames = UInt32(data.count) / bytesPerFrame
        let writeStatus = ExtAudioFileWrite(outputFile!, numberOfFrames, &bufferList)
        print("write status \(writeStatus)")
        let closeStatus = ExtAudioFileDispose(outputFile!)
        print("close status \(closeStatus)")
    }
}

enum SampleRate {
    case rate(Float64)
    
    var stringValue: String {
        return "\(float64Value)"
    }
    
    var float64Value: Float64 {
        switch self {
        case .rate(let sampleRate):
            return sampleRate
        }
    }
    
    private static let standardRate: Float64 = 44100
    static let availableRates: [SampleRate] = [.rate(standardRate), .rate(standardRate / 8), rate(standardRate / 64)]
}

extension URL {
    init(temporaryURLWithFileExtension fileExtension: String) {
        let uptime = mach_absolute_time()
        let filename = "\(uptime).\(fileExtension)"
        let tmpFolderString = (NSTemporaryDirectory() as NSString).appendingPathComponent(filename)
        print(tmpFolderString)
        self.init(fileURLWithPath: tmpFolderString)
    }
}
