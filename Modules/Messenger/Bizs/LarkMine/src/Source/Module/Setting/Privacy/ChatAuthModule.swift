//
//  ChatAuthModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/7/6.
//

import Foundation
import LarkOpenSetting
import RxSwift
import LarkContainer
import LarkSDKInterface
import RustPB
import EENavigator
import UniverseDesignToast
import LarkSettingUI
import LarkSetting

let chatAuthEntryModuleProvider: ModuleProvider = { userResolver in
    return GeneralBlockModule(
        userResolver: userResolver,
        title: BundleI18n.LarkMine.Lark_Core_WhoCanPrivateChatWithMe_Settings_Title) { (userResolver, from) in
        let vc = SettingViewController(name: "chatAuth")
        vc.patternsProvider = { return [
            .wholeSection(pair: PatternPair("chatAuthSetting", ""))
        ]}
        vc.registerModule(ChatAuthSettingModule(userResolver: userResolver), key: "chatAuthSetting")
        vc.navTitle = BundleI18n.LarkMine.Lark_Core_WhoCanPrivateChatWithMe_Settings_Title
        userResolver.navigator.push(vc, from: from)
    }
}

final class ChatAuthSettingModule: BaseModule {
    private var configAPI: ConfigurationAPI?

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.configAPI = try? self.userResolver.resolve(assert: ConfigurationAPI.self)
        self.configAPI?.getUserMsgAuth()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                SettingLoggerService.logger(.module(self.key)).info("api/userMsgAuth/get/res: msgType: \(response.msgType.rawValue)")
                self.type = response.msgType
                // 兼容逻辑，旧版本选择了allExceptDoc选项的用户，在新版版中调整为contact
                let featureGatingService = try? self.userResolver.resolve(assert: FeatureGatingService.self)
                let fgValue = featureGatingService?.staticFeatureGatingValue(with: "core.contacts.chat_permission") ?? false
                if fgValue && response.msgType == .allExceptDoc {
                    self.type = .contact
                }
                self.context?.reload()
            }, onError: { [weak self] (error) in
                guard let self = self, let window = self.context?.vc?.view.window else { return }
                UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Legacy_FailedtoLoadTryLater,
                                       on: window)
                SettingLoggerService.logger(.module(self.key)).error("api/userMsgAuth/get/res: error: \(error)")
            }).disposed(by: self.disposeBag)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        let featureGatingService = try? self.userResolver.resolve(assert: FeatureGatingService.self)
        let textOptimizedFG = featureGatingService?.staticFeatureGatingValue(with: "core.contacts.chat_permission") ?? false
        let everyone = NormalCellProp(title: BundleI18n.LarkMine.Lark_Core_WhoCanPrivateChatWithMe_Settings_All_Option,
                                      accessories: [.checkMark(isShown: self.type == .all)],
                                      onClick: { [weak self] _ in
            self?.update(type: .all)
        })
        let exceptDoc = NormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_WhoCanChatWithMeEveryoneExceptDocs,
                                       detail: BundleI18n.LarkMine.Lark_NewSettings_WhoCanChatWithMeEveryoneExceptDocsDesc,
                                      accessories: [.checkMark(isShown: self.type == .allExceptDoc)],
                                      onClick: { [weak self] _ in
            self?.update(type: .allExceptDoc)
        })
        let contact = NormalCellProp(title: BundleI18n.LarkMine.Lark_Core_Lark_Core_WhoCanPrivateChatWithMe_Settings_ContactsOnly_Option,
                                     detail: BundleI18n.LarkMine.Lark_Core_WhoCanPrivateChatWithMe_Settings_OrganizationMembersAndExternalContacts_Option,
                                     accessories: [.checkMark(isShown: self.type == .contact)],
                                     onClick: { [weak self] _ in
            self?.update(type: .contact)
        })
        let items = textOptimizedFG ? [contact, everyone] : [everyone, exceptDoc, contact]
        return SectionProp(items: items)
    }

    private var type: RustPB.Contact_V2_MsgType = .unknown

    private func update(type: RustPB.Contact_V2_MsgType) {
        let originalType = self.type
        self.type = type
        self.context?.reload()
        let logger = SettingLoggerService.logger(.module(self.key))
        configAPI?
            .setupUserMsgAuth(type: type)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.trackUserSettingPrivacyChat(type: type)
                logger.info("api/userMsgAuth/set/req: type: \(type.rawValue); res: ok")
            }, onError: { [weak self] (error) in
                self?.type = originalType
                self?.context?.reload()
                logger.error("api/userMsgAuth/set/req: type: \(type.rawValue); res: error: \(error)")
            }).disposed(by: self.disposeBag)
    }

    private func trackUserSettingPrivacyChat(type: RustPB.Contact_V2_MsgType) {
        var type = ""
        if self.type == .contact {
            type = "contacts"
        } else if self.type == .all {
            type = "all"
        }
        if !type.isEmpty {
            MineTracker.trackSettingWhoCanChatWithMe(type: type)
        }
    }
}
