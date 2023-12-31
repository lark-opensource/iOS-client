//
//  UploadShareStatusConfig.swift
//  ByteView
//
//  Created by fakegourmet on 2023/3/16.
//

import Foundation

// disable-lint: magic number
public struct UploadShareStatusConfig: Decodable {
    public let uploadStatusParticipantCount: Int

    static let `default` = UploadShareStatusConfig(uploadStatusParticipantCount: 20)
}
