//
//  DownscalingMidiGenerator.swift
//  ImagePlayer
//
//  Created by Luis Reisewitz on 02.04.17.
//  Copyright © 2017 ZweiGraf. All rights reserved.
//

import UIKit
import Toucan
import MIKMIDI

fileprivate let maxSize = CGSize(width: 50, height: 50)
class DownscalingMidiGenerator: MidiGenerator {
    required init(with image: UIImage, for viewController: UIViewController) {
        super.init(with: image, for: viewController)
    }
    
    override class func writeMidi(from image: UIImage, url: URL) -> MIKMIDISequence? {
        let downscaledImage = Toucan(image: image).resize(maxSize, fitMode: .clip).image
        return super.writeMidi(from: downscaledImage, url: url)
    }
}
