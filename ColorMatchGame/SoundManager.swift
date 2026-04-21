// SoundManager.swift
// ColorMatchGame
//
// Placeholder sound manager. Wire up AudioToolbox / AVFoundation here
// when adding real sound files to the project bundle.

import Foundation

final class SoundManager {

    static let shared = SoundManager()
    private init() {}

    // MARK: - Public API

    func playCorrect()   { /* play success chime */ }
    func playWrong()     { /* play soft error sound */ }
    func playTimeout()   { /* play gentle tick */ }
    func playGameOver()  { /* play fanfare */ }
    func playTap()       { /* play bubble pop */ }

    /*
     To implement:
     1. Add .caf / .wav files to the bundle.
     2. Import AudioToolbox.
     3. Use AudioServicesPlaySystemSound(soundID) or AVAudioPlayer for longer clips.

     Example:
        var correctSoundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &correctSoundID)
        AudioServicesPlaySystemSound(correctSoundID)
    */
}
