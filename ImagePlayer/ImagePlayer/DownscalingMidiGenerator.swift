//
//  DownscalingMidiGenerator.swift
//  ImagePlayer
//
//  Created by Luis Reisewitz on 02.04.17.
//  Copyright © 2017 ZweiGraf. All rights reserved.
//

import UIKit

class DownscalingMidiGenerator: MidiGenerator {
    required init(with image: UIImage, for viewController: UIViewController) {
        super.init(with: image, for: viewController)
    }
    
    override class func writeMidi(from image: UIImage, url: URL) {
        print("downscaling midi gernator writemidi")
        let imageData = Utils.data(for: image)
        writeMidi(from: imageData, url: url)
    }
}
