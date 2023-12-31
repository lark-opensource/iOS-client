//
//  SmartActionModules.swift
//  LarkAI
//
//  Created by sunyihe on 2022/12/27.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkAlertController
import LarkAccountInterface
import LarkSDKInterface
import RustPB
import LarkStorage
import LKCommonsLogging
import LarkFeatureGating
import LarkContainer
import EENavigator
import LarkOpenSetting
import LarkSettingUI
import LarkSetting
import LarkSearchCore

private func makeUserStore(userResolver: UserResolver) -> LarkStorage.KVStore {
    let uid = userResolver.userID
    return KVStores.udkv(space: .user(id: uid), domain: Domain.biz.setting)
}

// 企业百科
final class EnterpriseEntityModule: BaseModule {
    private lazy var configurationAPI: ConfigurationAPI? = {
        return try? self.userResolver.resolve(assert: ConfigurationAPI.self)
    }()

    private lazy var userStore = {
        return makeUserStore(userResolver: self.userResolver)
    }()

    private var enterpriseEntityWordDocEnable: Bool {
        AIFeatureGating.eewInDoc.isUserEnabled(userResolver: userResolver)
    }

    private var enterpriseEntityWordMinutesEnable: Bool {
        AIFeatureGating.eewInMinutes.isUserEnabled(userResolver: userResolver)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        guard userStore[KVPublic.Setting.enterpriseEntityTenantSwitch.key] else { return nil }

        let subs = createEnterpriseEntityWordItems()
        let isOn = subs.contains { key, _ in self.userStore[key] }
        var lingoBrandName = KVPublic.Setting.enterpriseName.value(forUser: userResolver.userID)
        // 百科名称用词典作为兜底
        if lingoBrandName.isEmpty {
            lingoBrandName = BundleI18n.LarkAI.Lark_Shared_LingoBrandName_Lingo_CNAsDictionary
        }

        let item = SwitchNormalCellProp(title: BundleI18n.LarkAI.Lark_Encyclopedia_SettingsFunctionName_AddedLingoVariable(lingoBrandName: lingoBrandName),
                                        detail: BundleI18n.LarkAI.Lark_Encyclopedia_SettingsFunctionDescriptionMobile_AddedLingoVariable(lingoBrandName: lingoBrandName),
                                        isOn: isOn) { [weak self] _, isOn in
            guard let self = self else { return }
            // 根据开关状态配置子开关的状态
            let messageEnabled = isOn
            var docEnabled: Bool?
            var minutesEnabled: Bool?
            if self.enterpriseEntityWordDocEnable {
                docEnabled = isOn
            }
            if self.enterpriseEntityWordMinutesEnable {
                minutesEnabled = isOn
            }
            let logger = SettingLoggerService.logger(.module(self.key))
            self.configurationAPI?.setEnterpriseEntityWordConfig(messageEnabled: messageEnabled, docEnabled: docEnabled, minutesEnabled: minutesEnabled)
                .subscribe(onNext: { [weak self] (_) in
                    guard let self = self else { return }
                    logger.info("api/setEnterpriseEntityWordConfig/req: all \(isOn); res:  success!")
                    subs.forEach { (key, _) in
                        self.userStore[key] = isOn
                    }
                    self.context?.reload()
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    logger.error("api/setEnterpriseEntityWordConfig/req: all \(isOn); res: error:\(error)")
                    self.context?.reload()
                }).disposed(by: self.disposeBag)
        }
        // 只有一个子开关时，不展示子开关
        let subItems = subs.count <= 1 ? [] : subs.map { key, str -> CellProp in
            return CheckboxNormalCellProp(title: str, boxType: .multiple, isOn: self.userStore[key]) { [weak self] _ in
                self?.enterpriseEntityWordItemRequest(defaultKey: key)
            }
        }
        return SectionProp(items: [item] + subItems)
    }

    private func createEnterpriseEntityWordItems() -> [(KVKey<Bool>, String)] {
        var enterpriseEntityWordItems: [(KVKey<Bool>, String)] = []
        enterpriseEntityWordItems.append(
            (KVPublic.Setting.enterpriseEntityMessage.key, BundleI18n.LarkAI.Lark_NewSettings_SmartComposeMessages)
        )
        if enterpriseEntityWordDocEnable {
            enterpriseEntityWordItems.append(
                (KVPublic.Setting.enterpriseEntityDoc.key, BundleI18n.LarkAI.Lark_NewSettings_SmartComposeDocs)
            )
        }
        if enterpriseEntityWordMinutesEnable {
            enterpriseEntityWordItems.append(
                (KVPublic.Setting.enterpriseEntityMinutes.key, BundleI18n.LarkAI.Lark_View_Minutes)
            )
        }
        return enterpriseEntityWordItems
    }

    /// 企业实体词子开关配置请求
    private func enterpriseEntityWordItemRequest(defaultKey: KVKey<Bool>) {
        let origin = self.userStore[defaultKey]
        let newValue = !origin
        var messageEnabled: Bool?
        var docEnabled: Bool?
        var minutesEnabled: Bool?
        if defaultKey.raw == KVPublic.Setting.enterpriseEntityMessage.key.raw {
            messageEnabled = newValue
        } else if defaultKey.raw == KVPublic.Setting.enterpriseEntityDoc.key.raw {
            docEnabled = newValue
        } else if defaultKey.raw == KVPublic.Setting.enterpriseEntityMinutes.key.raw {
            minutesEnabled = newValue
        }
        let logger = SettingLoggerService.logger(.module(self.key))
        self.configurationAPI?.setEnterpriseEntityWordConfig(messageEnabled: messageEnabled, docEnabled: docEnabled, minutesEnabled: minutesEnabled)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                logger.info("api/setEnterpriseEntityWordConfig/req \(defaultKey.raw): \(newValue); res: success")
                self.userStore[defaultKey] = newValue
                self.context?.reload()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                logger.error("api/setEnterpriseEntityWordConfig/req \(defaultKey.raw): \(newValue); res: error:\(error)")
                self.context?.reload()
            }).disposed(by: self.disposeBag)
    }
}

// 智能纠错
final class SmartCorrectionModule: BaseModule {
    private lazy var configurationAPI: ConfigurationAPI? = {
        return try? self.userResolver.resolve(assert: ConfigurationAPI.self)
    }()

    private lazy var userStore = {
        return makeUserStore(userResolver: self.userResolver)
    }()

    override func createSectionProp(_ key: String) -> SectionProp? {
        guard #available(iOS 13.0, *), AIFeatureGating.smartCorrect.isUserEnabled(userResolver: userResolver) else { return nil }
        let logger = SettingLoggerService.logger(.module(self.key))
        let item = SwitchNormalCellProp(title: BundleI18n.LarkAI.Lark_Settings_ASLSmartCorrectionTitle,
                                        detail: BundleI18n.LarkAI.Lark_Settings_ASLSmartCorrectionDesc,
                                        isOn: self.userStore[KVPublic.Setting.smartCorrect.key]) { [weak self] _, status in
            guard let self = self else { return }
            self.configurationAPI?.setSmartCorrectConfig(status)
                .subscribe(onNext: { [weak self] (_) in
                    guard let self = self else { return }
                    logger.info("api/set/req: status: \(status); res: success")
                    self.userStore[KVPublic.Setting.smartCorrect.key] = status
                    self.context?.reload()
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    logger.error("api/set/req: status: \(status); res: error:\(error)")
                    self.context?.reload()
                }).disposed(by: self.disposeBag)
        }
        return SectionProp(items: [item])
    }
}
// 智能补全
final class SmartComposeModule: BaseModule {
    private lazy var configurationAPI: ConfigurationAPI? = {
        return try? self.userResolver.resolve(assert: ConfigurationAPI.self)
    }()

    private lazy var userStore = {
        return makeUserStore(userResolver: self.userResolver)
    }()

    override func createSectionProp(_ key: String) -> SectionProp? {
        guard #available(iOS 13.0, *), AIFeatureGating.smartCompose.isUserEnabled(userResolver: userResolver) else { return nil }
        let logger = SettingLoggerService.logger(.module(self.key))
        let item = SwitchNormalCellProp(title: BundleI18n.LarkAI.Lark_NewSettings_SmartCompose,
                                        detail: BundleI18n.LarkAI.Lark_NewSettings_SmartComposeDescription,
                                        isOn: self.userStore[KVPublic.Setting.smartComposeMessage.key]) { [weak self] _, status in
            guard let self = self else { return }
            self.configurationAPI?.setSmartComposeConfig(status)
                .subscribe(onNext: { [weak self] (_) in
                    guard let self = self else { return }
                    logger.info("api/set/req: status: \(status); res: success")
                    self.userStore[KVPublic.Setting.smartComposeMessage.key] = status
                    self.context?.reload()
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    logger.error("api/set/req: status: \(status); res: error:\(error)")
                    self.context?.reload()
                }).disposed(by: self.disposeBag)
        }
        return SectionProp(items: [item])
    }
}
