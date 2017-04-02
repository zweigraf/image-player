//
//  PCMGenerator.swift
//  ImagePlayer
//
//  Created by Luis Reisewitz on 02.04.17.
//  Copyright © 2017 ZweiGraf. All rights reserved.
//

import UIKit
import AudioToolbox
import AVKit
import AVFoundation

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
    
    static let standardRate: Float64 = 44100
    static let availableRates: [SampleRate] = [.rate(standardRate), .rate(standardRate / 8), rate(standardRate / 64)]
}

class PCMGenerator: ImagePlaying {
    let wavURL = URL(temporaryURLWithFileExtension: "wav")
    let sampleRate = SampleRate.standardRate
    
    let image: UIImage
    weak var viewController: UIViewController?
    
    required init(with image: UIImage, for viewController: UIViewController) {
        self.image = image
        self.viewController = viewController
    }
    
    func prepareToPlay() {
        PCMGenerator.writeWav(from: image, url: wavURL, sampleRate: sampleRate)
    }
    
    func startPlayback() {
        playWav(url: wavURL)
    }
    
    func stopPlayback() {
        
    }
}

// MARK: - 🔊 Internal Playback Controls 🔊
fileprivate extension PCMGenerator {
    func playWav(url: URL) {
        guard let viewController = viewController else { return }
        let player = AVPlayer(url: url)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        viewController.present(playerVC, animated: true)
    }
}

// MARK: - 🎵 Audio 🎵
fileprivate extension PCMGenerator {
    static func writeWav(from image: UIImage, url: URL, sampleRate: Float64) {
        let imageData = Utils.data(for: image)
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
        
        // Initialize Pointer. Need to clean it up later ⚠️
        let intPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: intPointer, count: data.count)
        
        let buffer = AudioBuffer(mNumberChannels: numberOfChannels, mDataByteSize: UInt32(data.count), mData: intPointer)
        var bufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: buffer)
        
        let numberOfFrames = UInt32(data.count) / bytesPerFrame
        let writeStatus = ExtAudioFileWrite(outputFile!, numberOfFrames, &bufferList)
        print("write status \(writeStatus)")
        let closeStatus = ExtAudioFileDispose(outputFile!)
        print("close status \(closeStatus)")
        
        // Cleanup our Pointer 🚿
        intPointer.deinitialize()
        intPointer.deallocate(capacity: data.count)
    }
}
