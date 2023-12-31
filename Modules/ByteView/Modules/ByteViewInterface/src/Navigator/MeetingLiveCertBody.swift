//
//  MeetingLiveCertBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/30.
//

import Foundation

public struct MeetingLiveCertBody: CodablePathBody {
    public static let path: String = "/client/videochat/cert"

    public let token: String

    public init(token: String) {
        self.token = token
    }
}
