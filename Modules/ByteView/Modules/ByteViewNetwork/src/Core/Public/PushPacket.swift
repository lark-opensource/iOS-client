//
//  PushPacket.swift
//  ByteViewNetwork
//
//  Created by kiri on 2023/1/11.
//

import Foundation
import ByteViewCommon
import ByteViewTracker

public struct RawPushPacket {
    public let userId: String
    public let contextId: String
    public let command: NetworkCommand
    public let data: Data

    public init(userId: String, contextId: String, command: NetworkCommand, data: Data) {
        self.userId = userId
        self.contextId = contextId
        self.command = command
        self.data = data
    }
}

public struct PushPacket<T> {
    public let userId: String
    public let contextId: String
    public let command: NetworkCommand
    public let message: T

    public init(userId: String, contextId: String, command: NetworkCommand, message: T) {
        self.userId = userId
        self.contextId = contextId
        self.command = command
        self.message = message
    }
}
