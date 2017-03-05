//
//  MainViewController.swift
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
import CoreGraphics

// MARK: - ViewControllerUI
protocol ViewControllerUI {
    var view: UIView { get }
}

// MARK: - ✨ View Controller ✨
class MainViewController: UIViewController {
    // MARK: ✨ View Magic ✨
    
    init() {
        super.init(nibName: nil, bundle: nil)
        print("lol init")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = ui.view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ui.pickerButton.onTap { [weak self] _ in
            self?.openPicker()
        }
        ui.generateButton.onTap { [weak self] _ in
            self?.generate()
        }
    }

    // MARK: Properties
    
    let ui = MainViewControllerUI()
    
    var currentImage: UIImage? = nil {
        didSet {
            ui.imageView.image = currentImage
            ui.generateButton.isEnabled = currentImage != nil
        }
    }
}

// MARK: - 👆 UI Actions 👆
extension MainViewController {
    func openPicker() {
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
    
    func generate() {
        let image = currentImage!
        let imageURL = temporaryURL(fileExtension: "jpg")
        let wavURL = temporaryURL(fileExtension: "wav")
        copy(image: image, to: imageURL)
        writeWav(from: image, url: wavURL)
        playWav(url: wavURL)
    }
}

// MARK: - 🐫 Handling 🐫
extension MainViewController {
    func handle(image: UIImage) {
        currentImage = image
    }
}

// MARK: - 💾 Data Manipulation 💾
extension MainViewController {
    func jpegData(for image: UIImage, quality: CGFloat = 0.8) -> Data {
        return UIImageJPEGRepresentation(image, 0.8)!
    }
    
    func rawData(for image: UIImage) -> Data {
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
    
    func data(for image: UIImage) -> Data {
        return rawData(for: image)
    }
}

// MARK: - 🗄 File Stuff 🗄
extension MainViewController {
    func copy(image: UIImage, to location: URL) {
        let imageData = data(for: image)
        try! imageData.write(to: location)
    }
    
    func temporaryURL(fileExtension: String) -> URL {
        let uptime = mach_absolute_time()
        let filename = "\(uptime).\(fileExtension)"
        let tmpFolderString = (NSTemporaryDirectory() as NSString).appendingPathComponent(filename)
        print(tmpFolderString)
        return URL(fileURLWithPath: tmpFolderString)
    }
}

// MARK: - 🔊 Playback 🔊
extension MainViewController {
    func playWav(url: URL) {
        let player = AVPlayer(url: url)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        present(playerVC, animated: true)
    }
}

// MARK: - 🎵 Audio 🎵
extension MainViewController {
    func writePCM(data: Data, url: URL, sampleRate: Float64 = 44100, numberOfChannels: UInt32 = 2) {
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
    
    func writeWav(data: Data, url: URL) {
        let sampleRate: Float64 = 44100// / 2 / 2 / 2 / 2 / 2 / 2
        writePCM(data: data, url: url, sampleRate: sampleRate, numberOfChannels: 2)
    }
    
    func writeWav(from image: UIImage, url: URL) {
        let imageData = data(for: image)
        writeWav(data: imageData, url: url)
    }
}

// MARK: - MainViewControllerUI
class MainViewControllerUI: ViewControllerUI {
    lazy var view: UIView = {
        let view = UIView()
        
        let pickerButton = self.pickerButton
        view.addSubview(pickerButton)
        pickerButton.autoAlignAxis(toSuperviewAxis: .vertical)
        pickerButton.autoPinEdge(toSuperviewMargin: .top)
        
        let generateButton = self.generateButton
        view.addSubview(generateButton)
        generateButton.autoAlignAxis(toSuperviewAxis: .vertical)
        generateButton.autoPinEdge(toSuperviewMargin: .bottom)
        
        let imageView = self.imageView
        view.addSubview(imageView)
        imageView.autoPinEdge(toSuperviewMargin: .leading)
        imageView.autoPinEdge(toSuperviewMargin: .trailing)
        imageView.autoPinEdge(.top, to: .bottom, of: pickerButton, withOffset: 16)
        imageView.autoPinEdge(.bottom, to: .top, of: generateButton, withOffset: 16)
        
        return view
    }()
    
    let pickerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Open Picker", for: .normal)
        return button
    }()
    
    let generateButton: UIButton = {
        let button = UIButton()
        button.setTitle("Generate", for: .normal)
        // false by default, enabled by selecting image
        button.isEnabled = false
        return button
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
}
