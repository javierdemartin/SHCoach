//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by Javier de Martín Gil on 27/8/21.
//

import XCTest
import AVFAudio
import AVFoundation

fileprivate extension AVURLAsset {
    
    static func length(for url: URL) -> Double {
        let audioAsset = AVURLAsset(url: url)
        let duration = audioAsset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        
        return durationInSeconds
    }
}

/**
 Test all the functionality of both `SHCatalogCreator` & `SHCatalogInstance` capabilities of creating a
 custom `ShazamKit` catalog and audio matching.
 
 Both `SHCatalogCreator` & `SHCatalogMatcher` in the test use a custom mocked instance of
 `AVAudioEngine`, `FakeMicrophone`, as it's not possible to create a "real" hardware instance of a microphone.
 */
class Tests_iOS: XCTestCase {
    
    /// Full-length audio file of a song to match against
    private var correctLongSong = URL(fileURLWithPath: "vivaldi_full.mp3")
    
    /// Sample excerpt of the previous song to check if a match succeeded
    private var correctExcerptToMatch = URL(fileURLWithPath: "vivaldi_short_to_match.m4a")
    
    /// Sample excerpt of a song that's not going to be added to `SHCustomCatalog` causing the match to fail.
    private var incorrectExcerptToMatch = URL(fileURLWithPath: "not_vivaldi.m4a")
    
    /// Create a `SHCustomCatalog` with a full-length audio. And try to match that song
    /// against a short excerpt of another song that's not the one used on the original
    /// `SHCustomCatalog` causing it to fail.
    /// Will succeed if a match is **not** found.
    func testCheckWrongMatch() throws {
        
        let creator = SHCatalogCreator(audioEngine: FakeMicrophone())
        
        let matcher = SHCatalogMatcher(audioEngine: FakeMicrophone())
        
        let expectation = XCTestExpectation(description: "Check wrong match for a custom catalog")
        
        guard let audioFilePath = Bundle(for: type(of: self)).url(forResource: correctLongSong.fileNameWithoutExtension, withExtension: correctLongSong.pathExtension) else {
            fatalError("Could not find file.")
        }
        
        guard let wrongAudioToMatch = Bundle(for: type(of: self)).url(forResource: incorrectExcerptToMatch.fileNameWithoutExtension, withExtension: incorrectExcerptToMatch.pathExtension) else {
            fatalError("Could not find file.")
        }
        
        let correctSignature = try XCTUnwrap(creator.generateSignature(from: audioFilePath), "Failed to create signature")
        
        creator.customSignatures.append(
            SHCoachCustomSignatureModel(
                signature: correctSignature,
                mediaItemProperties: [.title: correctLongSong.fileNameWithoutExtension])
        )
        
        let catalog = try XCTUnwrap(creator.createCustomCatalog(with: creator.customSignatures), "Failed to create custom catalog")
        
        matcher.loadModel(model: catalog)
        
        let wrongSignature = try XCTUnwrap(creator.generateSignature(from: wrongAudioToMatch), "Failed to create signature")
        
        // Match a wrong song that does not exist in the custom catalog
        // to trigger a failed state
        matcher.match(signature: wrongSignature)
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2.0, execute: {
            
            if case .matchFound = matcher.state {
                fatalError("A match shouldn't have been made as both songs are different.")
            } else {
                expectation.fulfill()
            }
        })
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// Create a `SHCustomCatalog` with a full-length audio. And try to match that song
    /// against a short excerpt of that same song trying to simulate a user Shazaming a song.
    /// Will succeed if a match is found.
    func testMatchCorrectSongAgainstCustomCatalog() throws {
        
        let expectation = XCTestExpectation(description: "Correct match against song")
        
        guard let audioFilePath = Bundle(for: type(of: self)).url(forResource: correctLongSong.fileNameWithoutExtension, withExtension: correctLongSong.pathExtension) else {
            fatalError("Could not find file.")
        }
        
        guard let short = Bundle(for: type(of: self)).url(forResource: correctExcerptToMatch.fileNameWithoutExtension, withExtension: correctExcerptToMatch.pathExtension) else {
            fatalError("Could not find file.")
        }
        
        let creator = SHCatalogCreator(audioEngine: FakeMicrophone())
        
        let signature = creator.generateSignature(from: audioFilePath)!
        
        let signatureToMatch = creator.generateSignature(from: short)!
        
        let matcher = SHCatalogMatcher(audioEngine: FakeMicrophone())
        
        let customSignatureModel = SHCoachCustomSignatureModel(
            signature: signature,
            mediaItemProperties: [.title: correctLongSong.fileNameWithoutExtension])
        
        creator.customSignatures.append(customSignatureModel)
        
        let catalog = try XCTUnwrap(creator.createCustomCatalog(with: creator.customSignatures), "Failed to create custom catalog")
        
        matcher.loadModel(model: catalog)
        
        matcher.match(signature: signatureToMatch)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            
            if case .matchFound = matcher.state {
                expectation.fulfill()
            } else {
                fatalError("Song should've been matched correctly")
            }
        })
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// Read an audio file and
    /// `SHSignature.duration` should be smaller than the audio's file length due to silences
    /// omitted in the original song.
    ///
    func testCreateSignatureFromAudioFile() throws {
        
        guard let audioFilePath = Bundle(for: type(of: self)).url(forResource: correctLongSong.fileNameWithoutExtension, withExtension: correctLongSong.pathExtension) else {
            fatalError("Could not find 'Sample.pdf' file to test.")
        }
        
        let duration = AVURLAsset.length(for: audioFilePath)
        
        let creator = SHCatalogCreator(audioEngine: FakeMicrophone())
        
        guard let unwrappedSignature = try? XCTUnwrap(creator.generateSignature(from: audioFilePath)) else {
            fatalError("Shouldn't have reached this point")
        }
        
        // Signature's duration is going to be equal or shorter than the
        // duration of the original audio file.
        // This is due to silences in the original sound file being silenced
        // as they don't contain any information relevant to the signature.
        XCTAssertTrue(Int(unwrappedSignature.duration) <= Int(duration), "Signature's length should be equal or smaller than the original audio duration")
        XCTAssertTrue(unwrappedSignature.dataRepresentation.isEmpty == false, "Signature's data is empty")
    }
    
    /// Read a full length song, create a custom catalog and export it.
    /// Check if any error happens in the process and if the returned URL where the catalog has been stored in is valid.
    func testCreateCustomCatalogAndExport() throws {
        
        // Read a full length song which will be used to create the `SHCustomCatalog`
        guard let nonAudioFilePath = Bundle(for: type(of: self)).url(forResource: correctLongSong.fileNameWithoutExtension, withExtension: correctLongSong.pathExtension) else {
            fatalError("Could not find \(correctLongSong) in project.")
        }
        
        let creator = SHCatalogCreator(audioEngine: FakeMicrophone())
        
        guard let unwrappedSignature = try? XCTUnwrap(creator.generateSignature(from: nonAudioFilePath))
        else {
            fatalError("Error generating signature")
        }
        
        creator.customSignatures.append(SHCoachCustomSignatureModel(signature: unwrappedSignature, mediaItemProperties: [.title: UUID().uuidString]))
        
        let customCatalog = try XCTUnwrap(creator.createCustomCatalog())
        
        /// Minimum duration of the created signature should be greater than 1.0s
        XCTAssertTrue(customCatalog.minimumQuerySignatureDuration >= 1.0)
        
        let exportedCustomCatalogUrl = try XCTUnwrap(creator.export(customCatalog))
        
        XCTAssertTrue(exportedCustomCatalogUrl.isFileURL)
    }
}
