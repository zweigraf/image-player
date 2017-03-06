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
import SVProgressHUD

// MARK: - ViewControllerUI
protocol ViewControllerUI {
    var view: UIView { get }
}

// MARK: - ✨ View Controller ✨
class MainViewController: UIViewController {
    // MARK: ✨ View Magic ✨
    
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
        ui.sampleRateSegmentedControl.selectedSegmentIndex = 0
        
        currentImage = nil
        
        SVProgressHUD.setDefaultMaskType(.clear)
    }

    // MARK: Properties
    
    let ui = MainViewControllerUI()
    
    var currentImage: UIImage? {
        didSet {
            let generateElementsHidden = currentImage == nil
            ui.imageView.image = currentImage
            ui.generateButton.isHidden = generateElementsHidden
            ui.sampleRateSegmentedControl.isHidden = generateElementsHidden
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
            let sourceimage = info[UIImagePickerControllerEditedImage] as? UIImage ?? info[UIImagePickerControllerOriginalImage] as? UIImage
            guard let image = sourceimage else {
                print("no image")
                return
            }
            self?.pick(image: image)
        }
        present(picker, animated: true, completion: nil)
    }
    
    func generate() {
        // FIXME: does not show. why?
        SVProgressHUD.show()
        
        let image = currentImage!
        let sampleRate = SampleRate.availableRates[ui.sampleRateSegmentedControl.selectedSegmentIndex].float64Value
        
        let imageURL = URL(temporaryURLWithFileExtension: "jpg")
        let wavURL = URL(temporaryURLWithFileExtension: "wav")
        
        Utils.copy(image: image, to: imageURL)
        Utils.writeWav(from: image, url: wavURL, sampleRate: sampleRate)
        
        SVProgressHUD.dismiss()
        playWav(url: wavURL)
    }
}

// MARK: - 🐫 Handling 🐫
extension MainViewController {
    func pick(image: UIImage) {
        currentImage = image
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

// MARK: - MainViewControllerUI
class MainViewControllerUI: ViewControllerUI {
    lazy var view: UIView = {
        let view = UIView()
        
        let pickerButton = self.pickerButton
        view.addSubview(pickerButton)
        pickerButton.autoAlignAxis(toSuperviewAxis: .vertical)
        pickerButton.autoPinEdge(toSuperviewEdge: .top, withInset: 36)
        
        let generateButton = self.generateButton
        view.addSubview(generateButton)
        generateButton.autoAlignAxis(toSuperviewAxis: .vertical)
        generateButton.autoPinEdge(toSuperviewMargin: .bottom)
        
        let segmentedControl = self.sampleRateSegmentedControl
        view.addSubview(segmentedControl)
        segmentedControl.autoAlignAxis(toSuperviewAxis: .vertical)
        segmentedControl.autoPinEdge(.bottom, to: .top, of: generateButton, withOffset: -16)
        
        let imageView = self.imageView
        view.addSubview(imageView)
        imageView.autoPinEdge(toSuperviewMargin: .leading)
        imageView.autoPinEdge(toSuperviewMargin: .trailing)
        imageView.autoPinEdge(.top, to: .bottom, of: pickerButton, withOffset: 16)
        imageView.autoPinEdge(.bottom, to: .top, of: segmentedControl, withOffset: -16)
        
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
        return button
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let sampleRateSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: SampleRate.availableRates.map { $0.stringValue })
        return control
    }()
}
