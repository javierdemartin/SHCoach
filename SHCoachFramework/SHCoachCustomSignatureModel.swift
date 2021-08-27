//
//  SHCoachCustomSignatureModel.swift
//  SHCoachCustomSignatureModel
//
//  Created by Javier de Martín Gil on 1/9/21.
//

import Foundation
import ShazamKit

/// Custom model definition to store properties of a `SHSignature` when creating a custom catalog.
public struct SHCoachCustomSignatureModel: Hashable, Identifiable {
    public let id: UUID = UUID()
    /// For simplicity, demo app just uses the `.title`  property. Any user implementing this framework can add all the properties they want to the custom catalog.
    public var mediaItem: SHMediaItem
    internal let signature: SHSignature

    public init(signature: SHSignature, mediaItemProperties: [SHMediaItemProperty: Any]) {
        self.mediaItem = SHMediaItem(properties: mediaItemProperties)
        self.signature = signature
    }
}
