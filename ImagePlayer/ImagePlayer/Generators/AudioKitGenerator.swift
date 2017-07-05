//
//  AudioKitGenerator.swift
//  ImagePlayer
//
//  Created by Luis Reisewitz on 05.07.17.
//  Copyright © 2017 ZweiGraf. All rights reserved.
//

import UIKit
import AudioKit

class AudioKitGenerator {
    fileprivate let image: UIImage
    fileprivate var oscillator: AKOscillator?
    
    required init(with image: UIImage, for viewController: UIViewController) {
        self.image = image
    }
}

extension AudioKitGenerator: ImagePlaying {
    func prepareToPlay() {
        let data = Utils.data(for: image)
        let averageY = Utils.averageLuminosity(of: data)
        
        oscillator = AKOscillator()
        
        let frequency = Double(averageY) / 255 * 3000
        oscillator?.frequency = frequency
        
        print("Prepared AudioKit. AverageY \(averageY) results in frequency \(frequency)Hz")
    }
    
    func startPlayback() {
        AudioKit.output = oscillator
        AudioKit.start()
        
        oscillator?.start()
    }
    
    func stopPlayback() {
        AudioKit.stop()
    }
}
