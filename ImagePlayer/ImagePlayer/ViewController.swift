//
//  ViewController.swift
//  ImagePlayer
//
//  Created by Luis Reisewitz on 05.03.17.
//  Copyright © 2017 ZweiGraf. All rights reserved.
//

import UIKit
import LambdaKit
import Sensitive
import PureLayout
import AVKit
import AVFoundation
import AudioToolbox

class ViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
        print("lol init")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView()
        let button = UIButton()
        button.setTitle("Open Picker", for: .normal)
        button.onTap { [weak self] _ in
            self?.presentPicker()
        }
        view.addSubview(button)
        button.autoCenterInSuperview()
        self.view = view
    }

    func presentPicker() {
        let picker = UIImagePickerController()
        picker.didCancel = { picker in
            picker.dismiss(animated: true)
        }
        picker.didFinishPickingMedia = { [weak self] picker, info in
            picker.dismiss(animated: true)
            print(info)
            let sourceimage = info[UIImagePickerControllerEditedImage] as? UIImage ?? info[UIImagePickerControllerOriginalImage] as? UIImage
            guard let image = sourceimage else {
                print("no image")
                return
            }
            self?.handle(image: image)
        }
        present(picker, animated: true, completion: nil)
    }
    
    func handle(image: UIImage) {
        let imageURL = temporaryURL(fileExtension: "jpg")
        let wavURL = temporaryURL(fileExtension: "wav")
        copy(image: image, to: imageURL)
        writeWav(from: image, url: wavURL)
        playWav(url: wavURL)
    }
    
    func copy(image: UIImage, to location: URL) {
        let data = UIImageJPEGRepresentation(image, 0.8)!
        try! data.write(to: location)
    }
    
    func writeWav(from image: UIImage, url: URL) {
        let data = UIImageJPEGRepresentation(image, 0.8)!
        
        let formatID = kAudioFormatLinearPCM
        let formatFlags = AudioFormatFlags(kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked)
        let shortSize = UInt32(MemoryLayout<CShort>.stride)
        let bytesPerFrame = shortSize * 2
        
        var streamDesc = AudioStreamBasicDescription(mSampleRate: 44100, mFormatID: formatID, mFormatFlags: formatFlags, mBytesPerPacket: bytesPerFrame, mFramesPerPacket: 1, mBytesPerFrame: bytesPerFrame, mChannelsPerFrame: 2, mBitsPerChannel: shortSize * 8, mReserved: 0)
        
        var channelLayout = AudioChannelLayout()
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono
        
        let cfUrl = url as CFURL
        let fileType = kAudioFileWAVEType
        var outputFile: ExtAudioFileRef?
        
        let result = ExtAudioFileCreateWithURL(cfUrl, fileType, &streamDesc, &channelLayout, 0, &outputFile)
        print("create result \(result)")
        
        let intPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: intPointer, count: data.count)
        let buffer = AudioBuffer(mNumberChannels: 2, mDataByteSize: UInt32(data.count), mData: intPointer)
        var bufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: buffer)
        
        let numberOfFrames = UInt32(data.count) / bytesPerFrame
        let writeStatus = ExtAudioFileWrite(outputFile!, numberOfFrames, &bufferList)
        print("write status \(writeStatus)")
    }
    
    func temporaryURL(fileExtension: String) -> URL {
        let uptime = mach_absolute_time()
        let filename = "\(uptime).\(fileExtension)"
        let tmpFolderString = (NSTemporaryDirectory() as NSString).appendingPathComponent(filename)
        print(tmpFolderString)
        return URL(fileURLWithPath: tmpFolderString)
    }
    
    func playWav(url: URL) {
        let player = AVPlayer(url: url)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        present(playerVC, animated: true)
    }
}

