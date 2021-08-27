//
//  SHSessionStatus.swift
//  SHSessionStatus
//
//  Created by Javier de Martín Gil on 1/9/21.
//

import Foundation
import ShazamKit

public enum SHSessionStatus: Equatable, RawRepresentable {

    public typealias RawValue = String

    public init?(rawValue: RawValue) {

        switch rawValue {
        case "Idle":
            self = .idle
        default:
            self = .idle
        }
    }

    case idle
    case matching
    case matchFound(SHMatch)
    case failed

    public var rawValue: String {
        switch self {
        case .idle:
            return "Idle"
        case .matching:
            return "Matching..."
        case .matchFound(let sHMatch):

            return ListFormatter.localizedString(byJoining: sHMatch.mediaItems.compactMap({ $0.title }))
        case .failed:
            return "Failed"
        }
    }
}
