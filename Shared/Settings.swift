//
//  Settings.swift
//  Settings
//
//  Created by Javier de Martín Gil on 28/8/21.
//

import Foundation
import UniformTypeIdentifiers

class Settings: ObservableObject {

    let supportedAudioInputFiles: [UTType] = [.mp3, .mpeg4Audio, .audio]

    /// File path that contains the `SHCustomCatalog`
    @Published public var shazamModelURL: URL? = nil
}
