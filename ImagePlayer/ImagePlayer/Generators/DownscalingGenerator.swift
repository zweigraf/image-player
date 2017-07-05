//
//  DownscalingGenerator.swift
//  ImagePlayer
//
//  Created by Luis Reisewitz on 05.07.17.
//  Copyright © 2017 ZweiGraf. All rights reserved.
//

import UIKit
import Toucan

fileprivate let maxSize = CGSize(width: 50, height: 50)

class DownscalingGenerator<Wrapped: ImagePlaying>: ImagePlaying {
    let generator: Wrapped

    required init(with image: UIImage, for viewController: UIViewController) {
        let downscaledImage = Toucan(image: image).resize(maxSize, fitMode: .clip).image
        generator = Wrapped(with: downscaledImage, for: viewController)
    }
    
    func prepareToPlay() {
        generator.prepareToPlay()
    }
    
    func startPlayback() {
        generator.startPlayback()
    }
    
    func stopPlayback() {
        generator.stopPlayback()
    }
}
