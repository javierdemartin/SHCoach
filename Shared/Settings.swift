//
//  Settings.swift
//  Settings
//
//  Created by Javier de Martín Gil on 28/8/21.
//

import Foundation
import UniformTypeIdentifiers

class Settings: ObservableObject {

    /// Supported file types and extensions that can be imported from the file picker sheet.
    let supportedAudioInputFiles: [UTType] = [.mp3, .mpeg4Audio, .audio]

    /// File path that contains the `SHCustomCatalog`
    @Published public var shazamCatalogUrl: URL? = nil
}
