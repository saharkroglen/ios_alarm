import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Configure for alarm/notification sounds - should play even when device is silent
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    func playSound(named soundName: String) {
        // Ensure audio session is active
        configureAudioSession()
        
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "caf") else {
            print("Could not find sound file: \(soundName).caf in bundle")
            // List available files for debugging
            if let bundlePath = Bundle.main.resourcePath {
                let fileManager = FileManager.default
                do {
                    let contents = try fileManager.contentsOfDirectory(atPath: bundlePath)
                    let cafFiles = contents.filter { $0.hasSuffix(".caf") }
                    print("Available CAF files in bundle: \(cafFiles)")
                } catch {
                    print("Could not list bundle contents: \(error)")
                }
            }
            return
        }
        
        print("Attempting to play sound: \(soundURL.path)")
        
        do {
            // Stop any currently playing audio
            audioPlayer?.stop()
            
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.volume = 1.0
            audioPlayer?.numberOfLoops = 0 // Play once completely
            audioPlayer?.prepareToPlay()
            
            let success = audioPlayer?.play() ?? false
            print("Sound playback started: \(success)")
            print("Sound duration: \(audioPlayer?.duration ?? 0) seconds")
            
            if !success {
                print("Failed to start sound playback")
            }
        } catch {
            print("Error creating/playing audio player: \(error)")
        }
    }
    
    static func getSoundFiles() -> [String] {
        let bundle = Bundle.main
        let soundFiles = ["stars", "summer", "mistery"]
        var availableSounds: [String] = []
        
        for sound in soundFiles {
            if bundle.url(forResource: sound, withExtension: "caf") != nil {
                availableSounds.append("\(sound).caf")
            }
        }
        
        return availableSounds
    }
}
