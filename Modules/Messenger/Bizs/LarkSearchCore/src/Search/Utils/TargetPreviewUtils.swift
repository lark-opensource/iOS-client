//
//  TargetPreviewUtils.swift
//  LarkSearchCore
//
//  Created by ByteDance on 2022/10/11.
//

import Foundation
import UIKit
import LarkSDKInterface
import LarkMessengerInterface
import LarkModel
import LKCommonsLogging

public protocol TargetInfoTapDelegate: AnyObject {
    //获取dataSource时，如section和row都需要，则使用此delegate
    func presentPreviewViewController(section: Int?, row: Int?)
}

public final class TargetPreviewUtils {
    static let logger = Logger.log(TargetPreviewUtils.self, category: "TargetPreviewUtils")
    static let loggerKey = "TargetPreview.Utils: "

    public static func canTargetPreview(optionIdentifier: OptionIdentifier) -> Bool {
        Self.logger.info("\(Self.loggerKey) optionIdentifier type: \(optionIdentifier.type), optionIdentifier isCrypto: \(optionIdentifier.isCrypto)")
        return !(optionIdentifier.isCrypto ||
                 optionIdentifier.type == OptionIdentifier.Types.thread.rawValue ||
                 optionIdentifier.type == OptionIdentifier.Types.unknown.rawValue ||
                 optionIdentifier.type == OptionIdentifier.Types.department.rawValue ||
                 optionIdentifier.type == OptionIdentifier.Types.userGroup.rawValue ||
                 optionIdentifier.type == OptionIdentifier.Types.userGroupAssign.rawValue ||
                 optionIdentifier.type == OptionIdentifier.Types.newUserGroup.rawValue ||
                 optionIdentifier.type == OptionIdentifier.Types.myAi.rawValue)
    }

    public static func isThreadGroup(optionIdentifier: OptionIdentifier) -> Bool {
        let isThreadGroup = optionIdentifier.isThread && optionIdentifier.type == OptionIdentifier.Types.chat.rawValue
        Self.logger.info("\(Self.loggerKey) optionIdentifier isThreadGroup: \(isThreadGroup)")
        return isThreadGroup
    }

    public static func canTargetPreview(forwardItem: ForwardItem) -> Bool {
        Self.logger.info("\(Self.loggerKey) forwardItem type: \(forwardItem.type), forwardItem isCrypto: \(forwardItem.isCrypto)")
        return !(forwardItem.isCrypto ||
                 forwardItem.type == .threadMessage ||
                 forwardItem.type == .replyThreadMessage ||
                 forwardItem.type == .unknown ||
                 forwardItem.type == .myAi)
    }
    public static func isThreadGroup(forwardItem: ForwardItem) -> Bool {
        let isThreadGroup = forwardItem.isThread && forwardItem.type == .chat
        Self.logger.info("\(Self.loggerKey) forwardItem isThreadGroup: \(isThreadGroup)")
        return isThreadGroup
    }

    public static func canTargetPreview(chat: Chat) -> Bool {
        Self.logger.info("\(Self.loggerKey) chat isCrypto: \(chat.isCrypto)")
        return !(chat.isCrypto)
    }
    public static func isThreadGroup(chat: Chat) -> Bool {
        let isThreadGroup = (chat.chatMode == .threadV2 || chat.chatMode == .thread) && chat.type == .group
        Self.logger.info("\(Self.loggerKey) chat isThreadGroup: \(isThreadGroup)")
        return isThreadGroup
    }

    public static func canTargetPreview(searchResult: SearchResultType) -> Bool {
        switch searchResult.meta {
        case .chatter(let chatter):
            Self.logger.info("\(Self.loggerKey) searchResult chatter type: \(chatter.type)")
            return (chatter.type != .unknown)
        case .chat(let chat):
            Self.logger.info("\(Self.loggerKey) searchResult chat isCrypto: \(chat.isCrypto)")
            return !(chat.isCrypto)
        default:
            return false
        }
    }

    //chatter无需判断isThreadGroup
    public static func canTargetPreview(chatter: Chatter) -> Bool {
        Self.logger.info("\(Self.loggerKey) chatter type: \(chatter.type)")
        return (chatter.type != .unknown)
    }
}
