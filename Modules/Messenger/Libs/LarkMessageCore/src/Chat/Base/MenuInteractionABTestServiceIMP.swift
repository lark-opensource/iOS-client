//
//  ReplyFeatureTestManager.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/3/28.
//

import UIKit
import LarkMessageBase
import LarkSetting
import LKCommonsLogging
import LarkModel

public class MenuInteractionABTestServiceIMP: MenuInteractionABTestService {
    static let logger = Logger.log(MenuInteractionABTestServiceIMP.self, category: "MenuInteractionABTestServiceIMP")
    public let abTestResult: MeunABTestResult

    public var hitABTest: Bool {
        switch self.abTestResult {
        case .none:
            return false
        case .gentle:
            return true
        case .radical:
            return true
        }
    }

    public var replyMenuIcon: UIImage? {
        switch abTestResult {
        case .none:
            return nil
        case .gentle:
            return BundleResources.Menu.menu_quote
        case .radical:
            return BundleResources.Menu.menu_quote
        }
    }

    public var replyMenuTitle: String? {
        switch abTestResult {
        case .none:
            return nil
        case .gentle:
            return BundleI18n.LarkMessageCore.Lark_IM_Quote_Test_Button
        case .radical:
            return BundleI18n.LarkMessageCore.Lark_IM_Quote_Test_Button
        }
    }

    public var threadReplyMenuTitle: String? {
        switch abTestResult {
        case .none:
            return nil
        case .gentle:
            return BundleI18n.LarkMessageCore.Lark_IM_ReplyInThread_Test_Button
        case .radical:
            return BundleI18n.LarkMessageCore.Lark_IM_QReplyI_Test_Button

        }
    }

    public func replyMenuIcon(chat: Chat?) -> UIImage? {
        guard chat?.isCrypto != true else {
            return nil
        }
        return replyMenuIcon
    }

    public func replyMenuTitle(chat: Chat?) -> String? {
        guard chat?.isCrypto != true else {
            return nil
        }
        return replyMenuTitle

    }

    public func threadReplyMenuTitle(chat: Chat?) -> String? {
        guard chat?.isCrypto != true else {
            return nil
        }
        return threadReplyMenuTitle
    }

    public func hitABTest(chat: Chat?) -> Bool {
        guard chat?.isCrypto != true else {
            return false
        }
        return hitABTest
    }

    init(fgService: FeatureGatingService) {

        defer {
            Self.logger.info("MenuInteractionABTestServiceIMP init \(abTestResult.rawValue)")
        }

        guard fgService.dynamicFeatureGatingValue(with: "messenger.message.reply_optimize") else {
            abTestResult = .none
            return
        }

        abTestResult = fgService.dynamicFeatureGatingValue(with: "messenger.message.reply_optimize_exp1") ? .gentle : .radical
    }

}
