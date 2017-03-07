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
    
    override var prefersStatusBarHidden: Bool {
        return true
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
        
        // Clean up old files
        Utils.cleanTempFolder()
    }

    // MARK: Properties
    
    let ui = MainViewControllerUI()
    
    var currentImage: UIImage? {
        didSet {
            let generateElementsHidden = currentImage == nil
            ui.imageView.image = currentImage
            ui.bottomBackgroundView.isHidden = generateElementsHidden
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
        SVProgressHUD.show()
        
        DispatchQueue.background.async {
            let image = self.currentImage!
            let sampleRate = SampleRate.availableRates[self.ui.sampleRateSegmentedControl.selectedSegmentIndex].float64Value
            
            let imageURL = URL(temporaryURLWithFileExtension: "jpg")
            let wavURL = URL(temporaryURLWithFileExtension: "wav")
            
            Utils.copy(image: image, to: imageURL)
            Utils.writeWav(from: image, url: wavURL, sampleRate: sampleRate)
            
            SVProgressHUD.dismiss()
            DispatchQueue.main.async {
                self.playWav(url: wavURL)
            }
        }
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
        
        let imageView = self.imageView
        view.addSubview(imageView)
        imageView.autoPinEdgesToSuperviewEdges()
        
        // Top Background is pinned to top & the sides, and the pickerButton is pinned to top & bottom
        // of the top background view, effectively expanding it downwards.
        let topBGContentView = self.topBackgroundView.contentView
        topBGContentView.autoPinEdgesToSuperviewEdges()
        view.addSubview(self.topBackgroundView)
        
        let pickerButton = self.pickerButton
        topBGContentView.addSubview(pickerButton)
        pickerButton.autoAlignAxis(toSuperviewAxis: .vertical)
        pickerButton.autoPinEdge(toSuperviewEdge: .top, withInset: 16)
        pickerButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 16)
        
        self.topBackgroundView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        // Bottom Background is pinned to bottom & the sides, generateButton & segmentedControl are
        // pinned to top & bottom the bottom background view, effectively expanding it upwards.
        let bottomBGContentView = self.bottomBackgroundView.contentView
        bottomBGContentView.autoPinEdgesToSuperviewEdges()
        view.addSubview(self.bottomBackgroundView)
        
        let generateButton = self.generateButton
        bottomBGContentView.addSubview(generateButton)
        generateButton.autoAlignAxis(toSuperviewAxis: .vertical)
        generateButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 16)
        
        let segmentedControl = self.sampleRateSegmentedControl
        bottomBGContentView.addSubview(segmentedControl)
        segmentedControl.autoAlignAxis(toSuperviewAxis: .vertical)
        segmentedControl.autoPinEdge(.bottom, to: .top, of: generateButton, withOffset: -16)
        segmentedControl.autoPinEdge(toSuperviewEdge: .top, withInset: 16)
       
        self.bottomBackgroundView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        
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
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let sampleRateSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: SampleRate.availableRates.map { $0.stringValue })
        control.tintColor = .white
        return control
    }()
    
    let topBackgroundView = MainViewControllerUI.backgroundView()
    let bottomBackgroundView = MainViewControllerUI.backgroundView()
    
    private static func backgroundView() -> UIVisualEffectView {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        return view
    }
}
