//
//  VCMessagePreviews.swift
//  ByteViewNetwork
//
//  Created by 陈乐辉 on 2022/11/4.
//

import Foundation
import RustPB

public typealias VCMessagePreview = Videoconference_V1_VcMessagePreview
public typealias EmojiProperty = Feed_V1_Digest.Element.EmojiProperty
public typealias TextProperty = Feed_V1_Digest.Element.TextProperty
public typealias Digest = Feed_V1_Digest
public typealias DigestElement = Feed_V1_Digest.Element
public typealias SendUserData = Videoconference_V1_SendUserData

/// vc接入im互动消息推送
/// - PUSH_VC_MESSAGE_PREVIEWS = 2363
public struct VCMessagePreviews {
    public var previews: [VCMessagePreview]
}

extension VCMessagePreviews: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_VcMessagePushPreviews

    init(pb: Videoconference_V1_VcMessagePushPreviews) throws {
        self.previews = pb.previews
    }
}

extension VCMessagePreviews: CustomStringConvertible {
    public var description: String {
        String(indent: "VCMessagePreviews",
               "feedID: \(previews.first?.feedID)")
    }
}
