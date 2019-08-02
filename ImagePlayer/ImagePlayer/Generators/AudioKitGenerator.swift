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
    fileprivate var envelope: AKAmplitudeEnvelope?
    private var data: Data?
    private var playbackTimer: Timer?
    
    required init(with image: UIImage, for viewController: UIViewController) {
        self.image = image
    }
}

private extension Collection where Element == UInt8 {
    func sum() -> Int {
        let values = map { Int($0) }
        return values.reduce(.zero, +)
    }

    func mean() -> UInt8 {
        return UInt8(sum() / count)
    }
}
extension AudioKitGenerator: ImagePlaying {
    func prepareToPlay() {
        let data = Utils.data(for: image)
        self.data = data

//        let table = AKTable(.sawtooth)
//        table.sawtooth()
        let oscillator = AKOscillator(/*waveform: table*/)

//        let envelope = AKAmplitudeEnvelope(oscillator)
//        envelope.attackDuration = 0.01 / 4
//        envelope.decayDuration = 0.1 / 4
//        envelope.sustainLevel = 0.1 / 4
//        envelope.releaseDuration = 0.3 / 4

        self.oscillator = oscillator
//        self.envelope = envelope
    }
    
    func startPlayback() {
        AudioKit.output = oscillator // envelope
        try! AudioKit.start()
        oscillator?.start()

        var dataIndex = 0
        let timer = Timer(timeInterval: 0.25, repeats: true) { timer in
//            guard self.envelope?.isStopped == true else {
//                self.envelope?.stop()
//                return
//            }
            guard let data = self.data,
                dataIndex + 3 < data.count else {
                    timer.invalidate()
                    return
            }
            let bytes = data[dataIndex...dataIndex + 3]
            let byte = bytes.mean()
            let frequency = Double(byte) / 255 * 3000
            self.oscillator?.frequency = frequency

            self.envelope?.start()
            dataIndex += 4
        }
        RunLoop.main.add(timer, forMode: .defaultRunLoopMode)
        playbackTimer = timer
    }
    
    func stopPlayback() {
        playbackTimer?.invalidate()
        try! AudioKit.stop()
    }
}
