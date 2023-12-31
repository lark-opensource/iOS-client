//
//  PushEmojiPanel.swift
//  ByteViewNetwork
//
//  Created by lutingting on 2022/12/19.
//

import Foundation
import RustPB

/// - PUSH_EMOJI_PANEL = 5122;
/// - im_V1_PushEmojiPanel
public struct EmojiPanelPushMessages {

    public var emojiPanel: EmojiPanel
}

extension EmojiPanelPushMessages: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Im_V1_PushEmojiPanel
    init(pb: Im_V1_PushEmojiPanel) {
        self.emojiPanel = pb.emojiPanel.vcType
    }
}
