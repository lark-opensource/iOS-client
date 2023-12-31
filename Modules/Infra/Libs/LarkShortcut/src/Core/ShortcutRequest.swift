//
//  ShortcutRequest.swift
//  LarkShortcut
//
//  Created by kiri on 2023/11/16.
//

import Foundation

public struct ShortcutRequest {
    public let requestId: String
    public let shortcut: Shortcut
    // let progressHandler: ((Double) -> Void)?

    public init(requestId: String = "", shortcut: Shortcut) {
        if requestId.isEmpty {
            self.requestId = Util.uuid()
        } else {
            self.requestId = requestId
        }
        self.shortcut = shortcut
    }
}

public struct ShortcutResponse {
    public let request: ShortcutRequest
    public let actionResults: [ActionResult]

    public init(request: ShortcutRequest, actionResults: [ActionResult] = []) {
        self.request = request
        self.actionResults = actionResults
    }

    public struct ActionResult {
        public let startTime: Date
        public let endTime: Date
        public let result: Result<Any, Error>

        public init(startTime: Date, endTime: Date, result: Result<Any, Error>) {
            self.startTime = startTime
            self.endTime = endTime
            self.result = result
        }

        public var duration: TimeInterval {
            endTime.timeIntervalSince(startTime)
        }
    }
}
