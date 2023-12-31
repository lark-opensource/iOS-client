//
//  CheckAutoTranslateGuideHandler.swift
//  LarkChat
//
//  Created by 李勇 on 2019/7/18.
//

import Foundation
import Swinject
import EENavigator
import LKCommonsLogging
import LarkFeatureGating
import LarkSDKInterface
import LarkMessengerInterface
import LarkGuide
import LarkNavigator

/// 检查自动翻译引导
final class CheckAutoTranslateGuideHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    private static let logger = Logger.log(CheckAutoTranslateGuideHandler.self, category: "LarkChat.CheckAutoTranslateGuideHandler")
    private lazy var newGuideService: NewGuideService? = {
        return try? resolver.resolve(assert: NewGuideService.self)
    }()

    func handle(_ body: CheckAutoTranslateGuideBody, req: EENavigator.Request, res: Response) throws {
        res.end(resource: EmptyResource())
        let openAutoTranslateGuideKey = AutoTranslateGuideInfo.openAutoTranslateGuideKey
        let userGeneralSettings = try self.resolver.resolve(assert: UserGeneralSettings.self)
        CheckAutoTranslateGuideHandler.logger.info("body = \(body.messageToOrigin),\(body.chatIsAutoTranslate),\(body.messageLanguage)")
        CheckAutoTranslateGuideHandler.logger.info("targetLanguage = \(userGeneralSettings.translateLanguageSetting.targetLanguage)")
        /// 0：原文->译文 && 当前会话自动翻译关
        /// && 消息语言与翻译目标语言不一致(用来处理badcase：当手动翻译时，如果翻译失败则toast会弹在window上，需先过滤掉一些稳定失败的情况)
        guard !body.messageToOrigin, !body.chatIsAutoTranslate,
            body.messageLanguage != userGeneralSettings.translateLanguageSetting.targetLanguage else { return }
        /// 1：没有引导过
        let needShowGuide = self.needShowGuide(key: openAutoTranslateGuideKey)
        CheckAutoTranslateGuideHandler.logger.info("needShowGuide = \(needShowGuide)")
        guard needShowGuide else {
            return
        }
        /// 2：fg开
        /// 3：付费租户
        let userAppConfig = try self.resolver.resolve(assert: UserAppConfig.self)
        let isEnableAutoTranslation = userAppConfig.appConfig?.billingPackage.isEnableAutoTranslation ?? false
        CheckAutoTranslateGuideHandler.logger.info("isEnableAutoTranslation = \(isEnableAutoTranslation)")
        guard isEnableAutoTranslation else {
            return
        }
        /// 4：消息自动翻译关
        let messageSwitch = userGeneralSettings.translateLanguageSetting.messageSwitch
        CheckAutoTranslateGuideHandler.logger.info("messageSwitch = \(messageSwitch)")
        if messageSwitch {
            return
        }
        /// 增加一次手动翻译次数
        let guideInfo = self.getGuideConfig(openAutoTranslateGuideKey) ?? AutoTranslateGuideInfo()
        guideInfo.translateCount += 1
        self.setGuideConfig(openAutoTranslateGuideKey, guideInfo)
        CheckAutoTranslateGuideHandler.logger.info("guideInfo.translateCount = \(guideInfo.translateCount)")
        /// 5：手动翻译次数达到三次以上
        guard guideInfo.translateCount >= 3 else {
            return
        }
        /// 满足引导条件，present引导界面
        self.didShowGuide(key: openAutoTranslateGuideKey)
        let body = AutoTranslateGuideBody()
        navigator.present(body: body, from: req.from, prepare: { (vc) in
            vc.modalPresentationStyle = .overFullScreen
        }, animated: false)
    }

    private func needShowGuide(key: String) -> Bool {
        return newGuideService?.checkShouldShowGuide(key: key) ?? false
    }

    private func setGuideConfig<T: Encodable>(_ key: String, _ config: T) {
        newGuideService?.setGuideConfig(key: key, object: config)
    }

    private func getGuideConfig<T: Decodable>(_ key: String) -> T? {
        return newGuideService?.getGuideConfig(key: key)
    }

    private func didShowGuide(key: String) {
        newGuideService?.didShowedGuide(guideKey: key)
    }
}
