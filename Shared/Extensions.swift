//
//  Extensions.swift
//  Extensions
//
//  Created by Javier de Martín Gil on 1/9/21.
//

import Foundation

extension URL {
    var fileNameWithoutExtension: String {
        self.deletingPathExtension().lastPathComponent
    }
}
