//
//  IMCopyPatseMenuTracker.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/1/19.
//

import Foundation
import UIKit
import LarkCore
import LarkModel
import LarkRichTextCore
import LarkBaseKeyboard

public class IMCopyPasteMenuTracker {

    public static func trackCopy(chat: Chat?,
                                   message: Message?,
                                   byCommand: Bool,
                                   allSelect: Bool,
                                   text: NSAttributedString) {
        let value = getCopyImageAndVideoCountfor(text)
        IMTracker.Chat.Main.Click.Msg.copyClick(chat,
                                                message,
                                                byCommand: byCommand,
                                                allSelect: allSelect,
                                                imageCount: value.0,
                                                videoCount: value.1)

    }

    public static func trackPaste(chat: Chat?, text: NSAttributedString) {
        let value = getPasteImageAndVideoCountfor(text)
        IMTracker.Chat.Main.Click.Msg.pasteClick(chat,
                                                 imageCount: value.0,
                                                 videoCount: value.1)
    }

    private static func getCopyImageAndVideoCountfor(_ text: NSAttributedString) -> (Int, Int) {
        var imageCount = 0
        var videoCount = 0
        let copyImageKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.image.key")
        text.enumerateAttribute(copyImageKeyAttributedKey, in: NSRange(location: 0,
                                                                           length: text.length),
                                    options: [.longestEffectiveRangeNotRequired],
                                    using: { info, _, _  in
            if info != nil {
                imageCount += 1
            }
        })

        let copyVideoKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.video.key")
        text.enumerateAttribute(copyVideoKeyAttributedKey,
                                    in: NSRange(location: 0, length: text.length),
                                    options: [.longestEffectiveRangeNotRequired], using: { info, _, _  in
            if info != nil {
                videoCount += 1
            }
        })
        return (imageCount, videoCount)
    }

    private static func getPasteImageAndVideoCountfor(_ text: NSAttributedString) -> (Int, Int) {
        let imageCount = ImageTransformer.fetchAllImageAttachemnt(attributedText: text).count +
        ImageTransformer.fetchAllRemoteImageAttachemnt(attributedText: text).count
        let videoCount = VideoTransformer.fetchAllVideoAttachemnt(attributedText: text).count + VideoTransformer.fetchAllRemoteVideoAttachemnt(attributedText: text).count
        return (imageCount, videoCount)
    }

}
