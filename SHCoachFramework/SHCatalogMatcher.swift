//
//  SHCatalogMatcher.swift
//  SHCatalogMatcher
//
//  Created by Javier de Martín Gil on 27/8/21.
//

// This class is only available for iOS devices as it makes use of a standard set
// of frequencies only available on the hardware of those devices.

#if !targetEnvironment(macCatalyst) && !os(macOS)

import Foundation
import ShazamKit
import Combine

/**
    Use your microphone as an audio stream to match audio during a `ShazamKit` session against a custom Shazam catalog that you can import.
  
  - Important: Requires the user to enable microphone usage in the `Info.plist` file under `Privacy - Microphone Usage Description. Not doing so will result in a crash.
  */
public final class SHCatalogMatcher: NSObject, ObservableObject {

    /// Updates the current status of the `SHSession` identifying process
    @Published public var state: SHSessionStatus = .idle {
        didSet {
            libraryLogger.log("Matching status changed to \(self.state.rawValue)")
        }
    }

    /// Will access the microphone via `AVAudioEngine` and `AVAudioMixerNode` to
    /// convert the sound into one that's compatible with `ShazamKit`
    private var audioEngine: AVAudioEngineMockable
    
    private let mixerNode = AVAudioMixerNode()

    /// Session for the active ShazamKit match request
    private lazy var session: SHSession? = nil
    
    public init(audioEngine: AVAudioEngineMockable = AVAudioEngine()) {
        self.audioEngine = audioEngine
        super.init()

        /// Only configure the physical instance is it's being initialized from a non mocked object
        if audioEngine is AVAudioEngine {
            configureAudioEngine()
        }
    }

    private override init() {
        fatalError("Use of this initializer is discouraged as it doesn't allow mocking certain elemetns for testing.")
    }

    /// Append audio buffer data to the current `SHSession` used for matching,
    /// `audioEngine` will call this function when new audio data is available.
    private func addAudio(buffer: AVAudioPCMBuffer, audioTime: AVAudioTime) {
        // Add the audio to the current match request.
        session?.matchStreamingBuffer(buffer, at: audioTime)
    }

    /// Configure both audio engine and mixer inpupts.
    /// Installs a tap that calls `addAudio(buffer:audioTime)` whenever a new audio buffer is available.
    /// That tap provides access to the input of the audio engine.
    /// This method should only be called from the `init` as it only needs to be run once.
    private func configureAudioEngine() {
        // Get the native audio format of the engine's input bus.
        // Input node can be the device's microphone or an external Bluetooth microphone
        // this creates issues as both end's sampling frequencies don't match.
        let inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)

        guard let inputSources = AVAudioSession.sharedInstance().inputDataSources, !inputSources.isEmpty else {
            libraryLogger.error("Not configuring AVAudioEngine, no audio input sources")
            return
        }

        // Set an output format compatible with ShazamKit.
        // ShazamKit accepts a wide variety of smapling frecuencies: 16kHz, 32kHz, 44,1kHz & 48kHz.
        // Input from the built-in microphone on devices running iOS 14 and earlier is already in a format that's
        // compatible with ShazamKit. **Other microphones or input sources may not be compatible**.
        let outputFormat = AVAudioFormat(
            standardFormatWithSampleRate: audioEngine.inputNode.outputFormat(forBus: 0).sampleRate,
            channels: 1)

        // Create a mixer node to convert the input.
        audioEngine.attach(mixerNode)

        // Attach the mixer to the microphone input and the output of the audio engine.
        audioEngine.connect(audioEngine.inputNode, to: mixerNode, format: inputFormat)

        audioEngine.connect(mixerNode, to: audioEngine.outputNode, format: outputFormat)

        // Install a tap on the mixer node to capture the microphone audio.
        // And call `addAudio(buffer:audioTime)` when new data is available to perform a match.
        mixerNode.installTap(onBus: 0,
                             bufferSize: 8192,
                             format: outputFormat) { buffer, audioTime in
            // Add captured audio to the buffer used for making a match.
            self.addAudio(buffer: buffer, audioTime: audioTime)
        }
        
        libraryLogger.log("Initialized Audio Engine")
    }

    /// Start listening to the microphone using the tap on the mixer node after the custom catalog has been loaded.
    public func startListeningToMatch() throws {
        // Throw an error if the audio engine is already running.
        guard !audioEngine.isRunning else { return }

        let audioSession = AVAudioSession.sharedInstance()

        // Ask the user for permission to use the mic if required then start the engine.
        try audioSession.setCategory(.playAndRecord)
        audioSession.requestRecordPermission { [weak self] success in
            guard success, let self = self else { return }
            try? self.audioEngine.start()
        }
        
        libraryLogger.log("Started listening from microphone")
    }

    /// Call this when you no longer need more information about the matched item, such as `predictedCurrentMatchOffset`.
    public func stopListeningFromMicrophone() {
        // Check if the audio engine is already recording.
        guard !audioEngine.isRunning else { return }
        
        audioEngine.stop()
        libraryLogger.log("Stopped audio engine")
    }
    
    /// Load `SHSession` by importing a `SHCustomCatalog`.
    public func loadModel(model: SHCustomCatalog) {
        // Create a session if one doesn't already exist.
        if (session == nil) {
            
            self.session = SHSession(catalog: model)
            session?.delegate = self
        }
    }

    /// Start listening to the audio to find a match.
    /// Change `SHSessionStatus` to `.matching`
    public func match(_ catalog: SHCustomCatalog) throws {

        loadModel(model: catalog)

        try startListeningToMatch()
        
        state = .matching
    }

    /// Import a `SHCustomCatalog` from a given file's URL  located in the system that contains a `.shazamcatalog` file.
    /// If the custom catalog loads successfully it will start listening
    /// - Parameters:
    ///   - customCatalogUrl: `URL` pointing to the path where the `.shazamcatalog` file is
    ///   - startListening: `Bool` value indicating if after a successful import of the custom catalog the app should start listening to matches. If `false` user will need to manually call `startListeningToMatch()` to start listening to audio inputs from the microphone.
    public func match(from customCatalogUrl: URL, startListening: Bool = true) throws {
        // Create a session if one doesn't already exist.
        if (session == nil) {

            // Holds reference signatures thay ou generate from
            // audio you provide.
            let customCatalog = SHCustomCatalog()

            _ = customCatalogUrl.startAccessingSecurityScopedResource()

            try! customCatalog.add(from: customCatalogUrl)

            customCatalogUrl.stopAccessingSecurityScopedResource()

            self.session = SHSession(catalog: customCatalog)
            session?.delegate = self
        }

        // Start listening to the audio to find a match.
        if startListening {
            try startListeningToMatch()

            state = .matching
        } else {
            state = .idle
        }
    }

    /// Use current `SHSession` and check if the passed `SHSignature` object is a match.
    public func match(signature: SHSignature) {
        session?.match(signature)
    }
}

// MARK: - SHSessionDelegate

extension SHCatalogMatcher: SHSessionDelegate {

    public func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        
        libraryLogger.error("Did not find match for signature, error: \(error?.localizedDescription ?? "No error trace")")
        
        DispatchQueue.main.async {
            self.state = .failed
        }
    }

    /// Handle a correct match being acquired from the current `SHSession`
    public func session(_ session: SHSession, didFind match: SHMatch) {

        libraryLogger.info("Found match \(match.mediaItems.compactMap({ $0.title }))")

        DispatchQueue.main.async {
            self.state = .matchFound(match)
        }
    }
}
#endif
