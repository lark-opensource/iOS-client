//
//  VideoChatIdentifier.swift
//  ByteView
//
//  Created by chentao on 2019/4/24.
//

import Foundation

struct VideoChatIdentifier: Equatable, Hashable, CustomStringConvertible {
    let id: String
    let interactiveId: String?

    init(id: String, interactiveId: String? = nil) {
        self.id = id
        self.interactiveId = interactiveId
    }

    var description: String {
        if let interactiveID = interactiveId {
            return "(id: \(id), interactiveID: \(interactiveID))"
        } else {
            return id
        }
    }
}
