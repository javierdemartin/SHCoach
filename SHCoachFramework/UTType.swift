//
//  Extensions.swift
//  Extensions
//
//  Created by Javier de Martín Gil on 29/8/21.
//

import Foundation
import UniformTypeIdentifiers

public extension UTType {
    
    /// ShazamCatalog unique file identifier
    static var shazamCatalog: UTType {
        get {
            return UTType("com.apple.shazamcatalog")!
        }
    }
}

