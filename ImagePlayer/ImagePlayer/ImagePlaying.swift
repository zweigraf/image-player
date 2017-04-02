//
//  ImagePlaying.swift
//  ImagePlayer
//
//  Created by Luis Reisewitz on 02.04.17.
//  Copyright © 2017 ZweiGraf. All rights reserved.
//

import UIKit

protocol ImagePlaying {
    init(with image: UIImage, for viewController: UIViewController)
    
    func prepareToPlay()
    
    func startPlayback()
    
    func stopPlayback()
}
