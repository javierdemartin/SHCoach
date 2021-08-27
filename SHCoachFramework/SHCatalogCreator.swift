//
//  SHCatalogCreator.swift
//  SHCatalogCreator
//
//  Created by Javier de Martín Gil on 27/8/21.
//

import Foundation
import ShazamKit

/**

 Base class to create a custom shazam catalog. It has two posible entry points: record audio from your microphone or import an audio file. Both are compatible and can be used together to create a new custom catalog.
 
 - Important: Requires the user to enable microphone usage in the `Info.plist` file under `Privacy - Microphone Usage Description. Not doing so will result in a crash.
 */
public final class SHCatalogCreator: ObservableObject {

    private let mixerNode = AVAudioMixerNode()

    // Used to get audio from the microphone.
    // Group of connected AVAudioNodes. Each of which performs audio
    // signal generation/preocessing or I/O tasks
    private var audioEngine: AVAudioEngineMockable


    public init(audioEngine: AVAudioEngineMockable = AVAudioEngine()) {
        self.audioEngine = audioEngine

        #if !targetEnvironment(macCatalyst) && !os(macOS)
        if audioEngine is AVAudioEngine {
            configureAudioEngine()
        }
        #endif
    }

    /// Only contiguous audio samples will be passed to `SHSignatureGenerator` to maximize the output
    /// quality of the `SHSignature`.
    /// Shazam does not process raw audio buffer data but a special signature from the recorded audio.
    private lazy var signatureGenerator = SHSignatureGenerator()
    
    /// Source of truth of all the custom signatures being added.
    @Published public var customSignatures: [SHCoachCustomSignatureModel] = []

    public func createCustomCatalog(with signatures: [SHCoachCustomSignatureModel]) -> SHCustomCatalog? {

        guard !signatures.isEmpty else { return nil }

        let catalog = SHCustomCatalog()
        
        do {
            
            try signatures.forEach { signature in
                try catalog.addReferenceSignature(signature.signature, representing: [signature.mediaItem])
            }
            
        } catch {
            libraryLogger.error("Could not create custom catalog from \(signatures.count) with error: \(error.localizedDescription)")
        }
        
        return catalog
    }


    public func createCustomCatalog() -> SHCustomCatalog? {
        
        let catalog = SHCustomCatalog()
        
        do {
            // capturedSignatures is an array of [ReferenceSignature], our custom model type.
            try customSignatures.forEach { reference in
                try catalog.addReferenceSignature(reference.signature, representing: [reference.mediaItem])
            }
            
        } catch {

            libraryLogger.error("Could not create custom catalog from \(self.customSignatures.count) with error: \(error.localizedDescription)")
        }
        
        return catalog
    }
    
    /// Export a custom `SHCustomCatalog`. If `manualUrlPath` is not provided `catalog` will be saved into the user's temporary directory with a random `UUID` file name with extension of `.shazamcatalog`.
    /// Returned `URL` is only useful if you haven't provided `manualUrlPath` to know where the file has been saved to. If it's
    /// been provided it can be discarded thanks to `@discardableResult`.
    /// - Parameters:
    ///   - catalog: `SHCustomCatalog` to export
    ///   - to: Destination `URL` to save `catalog` to. If not pro
    /// - Returns: `URL` of the location which `catalog` has been saved to
    @discardableResult public func export(_ catalog: SHCustomCatalog, to manualUrlPath: URL? = nil) throws -> URL? {
        
        // If no specific URL to store the custom catalog is provided a new one is created on the temporary directory.
        let tempURL = manualUrlPath ?? URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("shazamcatalog")
        
        do {
            
            try catalog.write(to: tempURL)
            
            return tempURL
        } catch {
            print("Export error: \(error)")
            throw error
        }
    }
}

// MARK: - Create a signature from an audio file
extension SHCatalogCreator {
    
    /// Return the signature of an audio file.
    /// - Parameters: `URL` containing the audio file to create the `SHSignature` from.
    /// - Returns: If successful a `SHSignature`  object, on error it will be `nil`
    public func generateSignature(from audioURL: URL) -> SHSignature? {
        
        // Create an audio format that's compatible with ShazamKit.
        guard let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else {
            // Handle an error in creating the audio format.
            return nil
        }
        
        // Create a signature generator to generate the final signature.
        let signatureGenerator = SHSignatureGenerator()
        
        do {
            
            _ = audioURL.startAccessingSecurityScopedResource()
            
            // Create an object for reading the audio file.
            let audioFile = try AVAudioFile(forReading: audioURL)
            
            // Convert the audio to a supported format.
            SHCatalogCreator.convert(audioFile: audioFile, outputFormat: audioFormat) { buffer in
                do {
                    // Append portions of the converted audio to the signature generator.
                    try signatureGenerator.append(buffer, at: nil)
                } catch {
                    // Handle an error generating the signature.
                    libraryLogger.error("Could not generate signature from \(audioURL, privacy: .public) with error:  \(error.localizedDescription)")
                    return
                }
            }
            
            audioURL.stopAccessingSecurityScopedResource()
        } catch {
            // Handle an error reading the audio file.
            dump(error)
            libraryLogger.error("Error reading audio file: \(error.localizedDescription)")
            return nil
        }
        
        // Generate the signature.
        return signatureGenerator.signature()
    }
    
    /// Convert an audio file to a new format one chunk at a time.
    private static func convert(audioFile: AVAudioFile, outputFormat: AVAudioFormat, processConvertedBlock: (AVAudioPCMBuffer) -> Void) {
        // Set the size of the conversion buffer.
        let frameCount = AVAudioFrameCount(
            (1024 * 64) / (audioFile.processingFormat.streamDescription.pointee.mBytesPerFrame)
        )
        // Calculate the number of frames for the output buffer.
        let outputFrameCapacity = AVAudioFrameCount(
            round(Double(frameCount) * (outputFormat.sampleRate / audioFile.processingFormat.sampleRate))
        )
        
        // Create the input and output buffers for converting the file.
        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: frameCount),
              let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCapacity) else {
                  return
              }
        
        // Create the format for the converter.
        guard let converter = AVAudioConverter(from: audioFile.processingFormat, to: outputFormat) else {
            return
        }
        
        // Convert the audio file.
        while true {
            // Convert frames in the input buffer, writing them to the output buffer.
            let status = converter.convert(to: outputBuffer, error: nil) { inNumPackets, outStatus in
                do {
                    // Read a frame from the audio file into the input buffer.
                    try audioFile.read(into: inputBuffer)
                    outStatus.pointee = .haveData
                    return inputBuffer
                } catch {
                    // Check if it's the end of the file or if an error occurred.
                    if audioFile.framePosition >= audioFile.length {
                        outStatus.pointee = .endOfStream
                        return nil
                    } else {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                }
            }
            
            switch status {
            case .error:
                // An error occurred during conversion; handle the error.
                return
                
            case .endOfStream:
                // All of the input is converted.
                return
                
            case .inputRanDry:
                // Some data was converted, but no more is available.
                processConvertedBlock(outputBuffer)
                return
                
            default:
                processConvertedBlock(outputBuffer)
            }
            
            // Reset the size of the buffers.
            inputBuffer.frameLength = 0
            outputBuffer.frameLength = 0
        }
    }
}

// MARK: - Create a signature from the microphone
extension SHCatalogCreator {
    
    // Use the microphone as the source for generating a signature is
    // similar as using it from matching.
    
    // Configure as a mixer.

    #if !targetEnvironment(macCatalyst) && !os(macOS)
    // Configure both audio engine and mixer
    // Install a tap that calls your add audio function.
    // The tap provides access to the input of the audio engine
    // Call this function from the initialization code for your object
    // because you only need to set up the engine once
    private func configureAudioEngine() {


        guard let inputSources = AVAudioSession.sharedInstance().inputDataSources, !inputSources.isEmpty else {
            libraryLogger.error("Not configuring AVAudioEngine, no audio input sources")
            return
        }


        // Get the native audio format of the engine's input bus.
        let inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)

        // Set an output format compatible with ShazamKit.
        let outputFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)

        // Create a mixer node to convert the input.
        audioEngine.attach(mixerNode)

        // Attach the mixer to the microphone input and the output of the audio engine.
        audioEngine.connect(audioEngine.inputNode, to: mixerNode, format: inputFormat)
        audioEngine.connect(mixerNode, to: audioEngine.outputNode, format: outputFormat)

        // Install a tap on the mixer node to capture the microphone audio.
        mixerNode.installTap(onBus: 0,
                             bufferSize: 8192,
                             format: outputFormat) { buffer, audioTime in
            // Add captured audio to the buffer used for making a match.
            libraryLogger.info("Buffer of \(buffer.frameLength) at \(audioTime)")
            self.addAudio(buffer: buffer, audioTime: audioTime)
        }
    }
    #endif
    
    /// Should only be called after finishing recording from the microphone.
    /// - Parameter name: Dictionary of `SHMediaItemProperty` describing the audio.
    /// - Returns: Generated
    @discardableResult public func createRecordFromRecordedSignature(with properties: [SHMediaItemProperty: Any]) -> SHCoachCustomSignatureModel {
        let signature = signatureGenerator.signature()
        
        let customSignatureModel = SHCoachCustomSignatureModel(signature: signature, mediaItemProperties: properties)
        
        customSignatures.append(customSignatureModel)
        
        audioEngine.reset()

        libraryLogger.info("Appended new signature")
        
        return customSignatureModel
    }
    
    
    /// Add audio coming from the microphone to `SHSignatureGenerator`.
    /// If appending to the buffer an error occurred it will fail silently by logging an error to the console with the reason.
    /// - Parameters:
    ///   - buffer: New PCM audio sample to be added to the `signatureGenerator`
    ///   - audioTime: Timestamp of the newly captured audio sample
    private func addAudio(buffer: AVAudioPCMBuffer, audioTime: AVAudioTime) {
        
        do {
            try signatureGenerator.append(buffer, at: audioTime)
        } catch {
            libraryLogger.error("Error appending audio buffer to SHSignatureGenerator at time=\(audioTime) with error: \(error.localizedDescription)")
        }
    }
    
    /// Start listening to the microphone using the tap on the mixer node.
    /// Maybe you need to request access to the microphone.
    ///
    public func startListeningFromMicrophone() throws {
        
        // Throw an error if the audio engine is already running.
        guard !audioEngine.isRunning else { return }

        // Restart as it's recording a new audio sample and we want separate audio files
        // This current project implementation does not allow to pause in between audio files
        // to create signatures as it would result in less quality results.
        signatureGenerator = SHSignatureGenerator()

        let audioSession = AVAudioSession.sharedInstance()

        // Ask the user for permission to use the mic if required then start the engine.
        try audioSession.setCategory(.playAndRecord)
        audioSession.requestRecordPermission { [weak self] success in
            guard success, let self = self else { return }
            try? self.audioEngine.start()
        }
    }
    
    /// Call this when you no longer need more information about the matched item, such as `predictedCurrentMatchOffset`.
    /// Also call this whenever an error occurs in the delegate
    public func stopListeningFromMicrophone() {
        // Check if the audio engine is already recording.
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }
}
