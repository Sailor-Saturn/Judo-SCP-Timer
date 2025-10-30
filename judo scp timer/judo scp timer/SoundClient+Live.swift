// Copyright © Occam Technologies. All rights reserved.

import AVFoundation
import AudioToolbox
import Foundation

// Audio engine manager - uses lazy initialization
private nonisolated(unsafe) enum AudioEngineManagerKey {
  @MainActor static let manager = AudioEngineManager()
}

@MainActor
private final class AudioEngineManager {
  private let engine = AVAudioEngine()
  private let playerNode = AVAudioPlayerNode()
  private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
  private var isConfigured = false
  
  func configure() {
    guard !isConfigured else { return }
    
    engine.attach(playerNode)
    engine.connect(playerNode, to: engine.mainMixerNode, format: format)
    
    // Set volume to maximum for loud beeps
    engine.mainMixerNode.volume = 1.0
    
    do {
      try engine.start()
      isConfigured = true
    } catch {
      print("Failed to start audio engine: \(error)")
    }
  }
  
  func playBeep() {
    guard let format = format, isConfigured else {
      // Fallback to system sound if not configured
      AudioServicesPlaySystemSound(1054)
      return
    }
    
    // Generate a sharp, loud Tabata-style beep - very piercing and distinct
    let sampleRate = 44100.0
    let frequency = 2800.0 // Higher pitch for more piercing Tabata beep
    let duration = 0.12 // Slightly longer for more presence
    let frameCount = Int(sampleRate * duration)
    
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
      AudioServicesPlaySystemSound(1054)
      return
    }
    
    buffer.frameLength = AVAudioFrameCount(frameCount)
    
    let channelData = buffer.floatChannelData![0]
    for frame in 0..<frameCount {
      let t = Double(frame) / sampleRate
      let progress = Double(frame) / Double(frameCount)
      
      // Ultra-sharp attack with quick decay for Tabata-style beep
      let envelope: Float
      if progress < 0.05 {
        // Very quick, sharp attack - almost instant
        envelope = Float(progress / 0.05)
      } else if progress > 0.6 {
        // Quick decay
        envelope = Float((1.0 - progress) / 0.4)
      } else {
        // Strong sustain
        envelope = 1.0
      }
      
      // Add harmonics for more Tabata-like character - sharper, more digital sound
      let fundamental = sin(2.0 * .pi * frequency * t)
      let harmonic2 = 0.3 * sin(2.0 * .pi * frequency * 2.0 * t) // Second harmonic
      let harmonic3 = 0.15 * sin(2.0 * .pi * frequency * 3.0 * t) // Third harmonic
      
      // Combine harmonics for richer, more piercing Tabata sound
      let sample = fundamental + harmonic2 + harmonic3
      channelData[frame] = Float(sample * Double(envelope) * 0.85) // Much louder - Tabata level
    }
    
    playerNode.scheduleBuffer(buffer)
    playerNode.play()
  }
  
  func playStartBeep() {
    guard let format = format, isConfigured else {
      AudioServicesPlaySystemSound(1054)
      return
    }
    
    // Generate loud Tabata-style start beep - similar to countdown but longer
    let sampleRate = 44100.0
    let frequency = 2800.0 // Same high pitch as countdown beep for consistency
    let duration = 0.5 // Longer start beep for better noticeability
    let frameCount = Int(sampleRate * duration)
    
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
      AudioServicesPlaySystemSound(1054)
      return
    }
    
    buffer.frameLength = AVAudioFrameCount(frameCount)
    
    let channelData = buffer.floatChannelData![0]
    for frame in 0..<frameCount {
      let t = Double(frame) / sampleRate
      let progress = Double(frame) / Double(frameCount)
      
      // Ultra-sharp attack with quick decay - same as countdown beep
      let envelope: Float
      if progress < 0.05 {
        // Very quick, sharp attack - almost instant (same as countdown)
        envelope = Float(progress / 0.05)
      } else if progress > 0.6 {
        // Quick decay (same as countdown)
        envelope = Float((1.0 - progress) / 0.4)
      } else {
        // Strong sustain
        envelope = 1.0
      }
      
      // Add same harmonics as countdown beep for consistent Tabata character
      let fundamental = sin(2.0 * .pi * frequency * t)
      let harmonic2 = 0.3 * sin(2.0 * .pi * frequency * 2.0 * t) // Second harmonic (same as countdown)
      let harmonic3 = 0.15 * sin(2.0 * .pi * frequency * 3.0 * t) // Third harmonic (same as countdown)
      
      // Combine harmonics for same rich, piercing Tabata sound
      let sample = fundamental + harmonic2 + harmonic3
      channelData[frame] = Float(sample * Double(envelope) * 0.85) // Same volume as countdown
    }
    
    playerNode.scheduleBuffer(buffer)
    playerNode.play()
  }
}

extension SoundClient {
  public static var live: Self {
    // Configure audio session
    let audioSession = AVAudioSession.sharedInstance()
    
    do {
      // Set category for playback with high priority - ensures loud, clear beeps
      // Use .playback category without mixing to get maximum volume
      try audioSession.setCategory(.playback, mode: .default, options: [])
      try audioSession.setActive(true)
    } catch {
      print("Failed to setup audio session: \(error)")
    }
    
    // Configure the audio engine manager (lazy initialization)
    Task { @MainActor in
      AudioEngineManagerKey.manager.configure()
    }
    
    return .init(
      playBeep: {
        Task { @MainActor in
          AudioEngineManagerKey.manager.playBeep()
        }
      },
      playStartBeep: {
        Task { @MainActor in
          AudioEngineManagerKey.manager.playStartBeep()
        }
      }
    )
  }
}
