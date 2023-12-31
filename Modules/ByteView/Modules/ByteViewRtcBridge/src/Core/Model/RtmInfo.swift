//
//  RtmInfo.swift
//  ByteView
//
//  Created by kiri on 2022/9/17.
//

import Foundation

public struct RtmInfo {
    public let signature: String
    public let url: String
    public let token: String
    public let uid: String
    public init(signature: String, url: String, token: String, uid: String) {
        self.signature = signature
        self.url = url
        self.token = token
        self.uid = uid
    }
}

public struct RtmReceivedMessage {
    public let fromUid: RtcUID
    public let messageType: UInt8
    public let messageContext: UInt8
    public let packet: Data
}

public protocol RtmSendMessage {
    var requestId: String { get }
    var messageType: UInt8 { get }
    var messageContext: UInt8 { get }
    var packet: Data { get }
}
