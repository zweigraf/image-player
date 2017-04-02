//
//  MidiGenerator.swift
//  ImagePlayer
//
//  Created by Luis Reisewitz on 02.04.17.
//  Copyright © 2017 ZweiGraf. All rights reserved.
//

import UIKit
import MIKMIDI

class MidiGenerator: ImagePlaying {
    // MARK: Properties
    
    let midiURL = URL(temporaryURLWithFileExtension: "midi")
    var sequencer: MIKMIDISequencer?
    let image: UIImage
    
    // MARK: ImagePlaying Conformance
    
    required init(with image: UIImage, for viewController: UIViewController) {
        self.image = image
    }
    
    func prepareToPlay() {
        type(of: self).writeMidi(from: image, url: midiURL)
    }
    
    func startPlayback() {
        playMidi(from: midiURL)
    }
    
    func stopPlayback() {
        pauseMidi()
    }
    
    // MARK: Midi Writing
    
    class func writeMidi(from image: UIImage, url: URL) {
        print("midi gernator writemidi")
        let imageData = Utils.data(for: image)
        try? writeMidi(from: imageData, url: url)
    }
    
    static func writeMidi(from data: Data, url: URL) throws {
        // Initialize Pointer. Need to clean it up later ⚠️
        let intPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: intPointer, count: data.count)
        
        
        let sequence = MIKMIDISequence()
        let redTrack = try! sequence.addTrack()
        /*        let greenTrack = try! sequence.addTrack()
         let blueTrack = try! sequence.addTrack()
         let alphaTrack = try! sequence.addTrack()*/
        
        // Iterating through all data in 4-step, ignoring if there are any rest bytes
//        let iterations = data.count / 4
        for iteration in 0...1000 {
            let r = (intPointer + iteration * 4 + 0).pointee
            let g = (intPointer + iteration * 4 + 1).pointee
            let b = (intPointer + iteration * 4 + 2).pointee
            var redNote = MIDINoteMessage(channel: 1, note: r, velocity: g, releaseVelocity: 0, duration: Float32(b) / 25)
            let redEvent = MIKMIDIEvent(timeStamp: MusicTimeStamp(iteration), midiEventType: .midiNoteMessage, data: Data(bytes: &redNote, count: MemoryLayout<MIDINoteMessage>.size))
            redTrack.addEvent(redEvent!)
            
            /*
             let a = intPointer + iteration * 4 + 3*/
        }
        
        try! sequence.write(to: url)
        
        // Cleanup our Pointer 🚿
        intPointer.deinitialize()
        intPointer.deallocate(capacity: data.count)
    }
}

// MARK: - Internal Playback Controls
fileprivate extension MidiGenerator {
    func playMidi(from url: URL) {
        guard let sequence = try? MIKMIDISequence(fileAt: url) else { return }
//        sequence.setOverallTempo(240)
        sequencer = MIKMIDISequencer(sequence: sequence)
        
        sequencer?.startPlayback()
    }
    
    func pauseMidi() {
        sequencer?.stop()
    }
}
