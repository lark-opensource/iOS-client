//
//  ModelService.swift
//  LarkInterface
//
//  Created by lichen on 2018/8/6.
//

import UIKit
import Foundation
import LarkModel
import RustPB
import LarkMessageBase
import LarkContainer

public protocol ModelService {
    typealias URLPreviewProvider = (_ elementID: String, _ originURL: String) -> NSAttributedString?
    typealias CopyValueProvider = (_ currentSubStr: String, _ attributes: [NSAttributedString.Key: Any]) -> String?

    func messageSummerize(_ message: Message) -> String

    func messageSummerize(_ message: Message, partialReplyInfo: PartialReplyInfo?) -> String

    func copyMessageSummerize(_ message: Message, selectType: CopyMessageSelectedType, copyType: CopyMessageType) -> String
    func copyMessageSummerizeAttr(_ message: Message, selectType: CopyMessageSelectedType, copyType: CopyMessageType) -> NSAttributedString
    func getEventTimeSummerize(_ message: Message) -> String
    func getCalendarBotTimeSummerize(_ message: Message) -> String
    func copyString(richText: RustPB.Basic_V1_RichText,
                    docEntity: RustPB.Basic_V1_DocEntity?,
                    selectType: CopyMessageSelectedType,
                    urlPreviewProvider: URLPreviewProvider?,
                    hangPoint: [String: RustPB.Basic_V1_UrlPreviewHangPoint],
                    copyValueProvider: CopyValueProvider?) -> String
    func copyStringAttr(richText: RustPB.Basic_V1_RichText,
                    docEntity: RustPB.Basic_V1_DocEntity?,
                    selectType: CopyMessageSelectedType,
                    urlPreviewProvider: URLPreviewProvider?,
                    hangPoint: [String: RustPB.Basic_V1_UrlPreviewHangPoint],
                    copyValueProvider: CopyValueProvider?,
                    userResolver: UserResolver) -> NSAttributedString
}
