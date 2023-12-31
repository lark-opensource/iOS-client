//
//  MineTranslateSettingViewModel.swift
//  LarkMine
//
//  Created by zhenning on 2020/02/11.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import EENavigator
import LarkUIKit
import UniverseDesignToast
import LarkSDKInterface
import LarkModel
import LarkLocalizations
import LKCommonsLogging
import LKMetric
import RustPB
import LarkTab
import LarkContainer
import LarkNavigation
import LarkSetting

final class MineTranslateScopeMappingModel {
    /// 映射scope Int值到文案
    static func scopeIntToDisplayText(userResolver: UserResolver) -> [Int: String] {
        var scopes = [RustPB.Im_V1_TranslateScopeMask.larkMessageMask.rawValue: BundleI18n.LarkMine.Lark_NewSettings_AutoTranslateMessage,
                      RustPB.Im_V1_TranslateScopeMask.webXml.rawValue: BundleI18n.LarkMine.Lark_Chat_SetWebAutoTranslate,
                      RustPB.Im_V1_TranslateScopeMask.docMask.rawValue: BundleI18n.LarkMine.Lark_Chat_TranslateDocs,
                      RustPB.Im_V1_TranslateScopeMask.email.rawValue: BundleI18n.LarkMine.Mail_Translations_AutoMailSetting,
                      RustPB.Im_V1_TranslateScopeMask.videoConference.rawValue: BundleI18n.LarkMine.View_G_MeetingChat_TickBox]
        if Self.supportMoments(userResolver: userResolver) {
            scopes[RustPB.Im_V1_TranslateScopeMask.moments.rawValue] = Tab.moment.remoteName ?? Tab.moment.tabName
        }
        return scopes
    }

    // 顺序展示文案
    // 消息, 文档正文和评论, 网页, Mail，视频会议聊天，公司圈
    static func displayTextInorder(userResolver: UserResolver) -> [Int] {
        var scopes = [RustPB.Im_V1_TranslateScopeMask.larkMessageMask.rawValue,
                        RustPB.Im_V1_TranslateScopeMask.docMask.rawValue,
                        RustPB.Im_V1_TranslateScopeMask.webXml.rawValue,
                        RustPB.Im_V1_TranslateScopeMask.email.rawValue,
                        RustPB.Im_V1_TranslateScopeMask.videoConference.rawValue]
        if Self.supportMoments(userResolver: userResolver) {
            scopes.append(RustPB.Im_V1_TranslateScopeMask.moments.rawValue)
        }
        return scopes
    }

    static func supportMoments(userResolver: UserResolver) -> Bool {
        guard Self.fgValueBg(key: FeatureGatingManager.Key("moments.client.translation"), userResolver: userResolver) else { return false }
        let navigationService = try? userResolver.resolve(type: NavigationService.self)
        let hadMomentTab = navigationService?.checkInTabs(for: .moment) ?? false
        return hadMomentTab
    }
    /// (scope, 文案)数组
    static func createScopeTitles(userResolver: UserResolver, config scopeConfiguration: [Int: Bool]) -> [(Int, String)] {
        var scopeTitles: [(Int, String)] = []

        // 顺序遍历，按照文案顺序
        // displayTextInorder 客户度支持展示的选项顺序
        // scopeConfiguration.keys 服务端下发的可以展示的所有选项
        for scopeIndex in displayTextInorder(userResolver: userResolver) where scopeConfiguration.keys.contains(scopeIndex) {
            let scopeIntToDisplayTextMap = scopeIntToDisplayText(userResolver: userResolver)
            if let displayText = scopeIntToDisplayTextMap[scopeIndex] {
                // 网页、mail 判断FG
                if (scopeIndex == RustPB.Im_V1_TranslateScopeMask.webXml.rawValue && !Self.fgValueBg(key: .translateSettingsV2WebEnable, userResolver: userResolver))
                    || (scopeIndex == RustPB.Im_V1_TranslateScopeMask.email.rawValue && !Self.fgValueBg(key: .translateSettingsMailEnable, userResolver: userResolver)) {
                    continue
                }
                scopeTitles.append((scopeIndex, displayText))
            }
        }
        return scopeTitles
    }

    static func fgValueBg(key: FeatureGatingManager.Key, userResolver: UserResolver) -> Bool {
        let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self)
        let fgValue = featureGatingService?.staticFeatureGatingValue(with: key)
        return fgValue ?? false
    }
}

/// 翻译设置vm
final class MineTranslateSettingViewModel {
    private let disposeBag = DisposeBag()
    private static let logger = Logger.log(MineTranslateSettingViewModel.self, category: "TranslateLanguage")
    let metricLogger = MineMetric()

    weak var targetVC: UIViewController?

    /// 用户常用设置
    private let userGeneralSettings: UserGeneralSettings
    private let userAppConfig: UserAppConfig
    private let router: MineTranslateSettingRouter
    private let userResolver: UserResolver
    /// 全局翻译设置
    private var currGloabalScopes: Int = 0
    /// 是否能展示"自动翻译以下内容section
    private var isEnableAutoTranslation: Bool {
        return self.userAppConfig.appConfig?.billingPackage.isEnableAutoTranslation ?? false
    }
    /// 刷新表格视图
    private let refreshPublish = PublishSubject<Void>()

    /// 数据源
    private(set) var items: [[MineTranslateItemProtocol]] = []
    /// 自动翻译
    private(set) var autoTranslateItems: [MineTranslateItemProtocol] = []
    private(set) var headerViews: [() -> UIView] = []
    private(set) var footerViews: [() -> UIView] = []
    var refreshDriver: Driver<()> {
        return refreshPublish.asDriver(onErrorJustReturn: ())
    }

    init(userResolver: UserResolver,
         userGeneralSettings: UserGeneralSettings,
         userAppConfig: UserAppConfig,
         router: MineTranslateSettingRouter
    ) {
        self.userResolver = userResolver
        self.userGeneralSettings = userGeneralSettings
        self.userAppConfig = userAppConfig
        self.router = router
        /// 设置初始值
        self.items = self.createDataSource(userResolver: self.userResolver)
        self.headerViews = self.createHeaderViews()
        self.footerViews = self.createFooterViews()
        /// 监听信号
        self.userGeneralSettings.translateLanguageSettingDriver.skip(1)
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.items = self.createDataSource(userResolver: self.userResolver)
                self.headerViews = self.createHeaderViews()
                self.footerViews = self.createFooterViews()
                self.refreshPublish.onNext(())
            }).disposed(by: self.disposeBag)

        if userGeneralSettings.translateLanguageSetting.srcLanugages.isEmpty {
            metricLogger.log(metric: BusinessID.Settings.GenenalSetting.openSettingFailed)
        } else {
            metricLogger.log(metric: BusinessID.Settings.GenenalSetting.openSetting)
        }
    }

    /// 创建数据源
    private func createDataSource(userResolver: UserResolver) -> [[MineTranslateItemProtocol]] {
        var tempItems: [[MineTranslateItemProtocol]] = []
        /// section 0 内容翻译为
        let tragetLanguageItem = MineTranslateDetailModel(
            cellIdentifier: MineTranslateDetailCell.lu.reuseIdentifier,
            title: BundleI18n.LarkMine.Lark_NewSettings_TranslateContentInto,
            detail: self.getTranslateLanguageValue(),
            isDetailRight: true,
            tapHandler: { [weak self] in
                guard let `self` = self else { return }
                self.router.pushTranslateTagetLanguageSettingController()
                if self.userGeneralSettings.translateLanguageSetting.trgLanguagesConfig.isEmpty {
                    self.metricLogger.log(metric: BusinessID.Settings.TargetLanguageSetting.openTargetLanguageFailed)
                } else {
                    self.metricLogger.log(metric: BusinessID.Settings.TargetLanguageSetting.openTargetLanguage)
                }
            }
        )
        tempItems.append([tragetLanguageItem])
        /// section 1 翻译显示的效果
        tempItems.append(self.translateConfigurationSectionItems())
        /// section 2 自动翻译以下内容
        if self.isEnableAutoTranslation {
            let autoTranslateGlobalSwitch = self.userGeneralSettings.translateLanguageSetting.autoTranslateGlobalSwitch
            self.autoTranslateItems = self.translateScopeSectionItems(userResolver: userResolver, isGeneralOpen: autoTranslateGlobalSwitch)
            tempItems.append(self.autoTranslateItems)
        }

        return tempItems
    }

    /// 全局翻译效果设置
    private func translateConfigurationSectionItems() -> [MineTranslateItemProtocol] {
        var sectionItems: [MineTranslateItemProtocol] = []
        /// 翻译后的翻译效果
        let translateLanguageSetting = self.userGeneralSettings.translateLanguageSetting
        let isWithOriginal = translateLanguageSetting.globalConf.rule == .withOriginal
        let originDoc = self.getTranlateOriginDoc(targetLanguage: translateLanguageSetting.targetLanguage)
        let translateDoc = translateLanguageSetting.trgLanguagesConfig[translateLanguageSetting.targetLanguage]?.translationDoc
        sectionItems.append(MineTranslateDisplayModel(
            cellIdentifier: MineTranslateDisplayCell.lu.reuseIdentifier,
            status: isWithOriginal,
            translateDoc: translateDoc,
            originDoc: originDoc,
            switchHandler: { [weak self] onlyTranslation in
                guard let `self` = self else { return }
                var configuration = RustPB.Im_V1_LanguagesConfiguration()
                configuration.rule = onlyTranslation ? RustPB.Basic_V1_DisplayRule.onlyTranslation : RustPB.Basic_V1_DisplayRule.withOriginal
                self.updateGlobalConf(globalConf: configuration)
                MineTracker.trackTranslateEffectSetting(action: onlyTranslation
                    ? TranslateEffectType.onlyTranslation
                    : TranslateEffectType.withOriginal)
            }
        ))
        /// 按语言设置
        sectionItems.append(MineTranslateTitleModel(
            cellIdentifier: MineTranslateTitleCell.lu.reuseIdentifier,
            title: BundleI18n.LarkMine.Lark_NewSettings_TranslationDisplaySetByLanguage,
            tapHandler: { [weak self] in
                guard let `self` = self else { return }
                self.router.pushLanguagesListSettingController(currGloabalScopes: nil, detailModelType: .translateStyleEffect)
            }
        ))
        return sectionItems
    }

    /// 翻译scope设置section，isGenenalOpen：总开关是否开启
    private func translateScopeSectionItems(userResolver: UserResolver, isGeneralOpen: Bool) -> [MineTranslateItemProtocol] {
        self.autoTranslateItems.removeAll()

        /// (scope, 文案)数组
        let config = self.userGeneralSettings.translateLanguageSetting.translateScopeConfiguration
        let scopeTitles: [(Int, String)] = MineTranslateScopeMappingModel.createScopeTitles(userResolver: userResolver, config: config)
        /// 设置的全局的scope
        let scopes = self.userGeneralSettings.translateLanguageSetting.translateScope
        /// 记录当前globalScopes设置
        self.currGloabalScopes = 0
        var hasScopeOpen = false
        scopeTitles.forEach { (scope, _) in
            let isOn = (scopes & scope) != 0
            if isOn {
                hasScopeOpen = true
                self.currGloabalScopes += scope
            }
        }
        MineTranslateSettingViewModel.logger.debug("translate: gloabalScopes get update currGloabalScopes = \(self.currGloabalScopes)")

        let isFinalOpen = isGeneralOpen && hasScopeOpen
        /// 自动翻译一级总开关
        let autoTranslateItem = MineTranslateSwitchModel(
            cellIdentifier: MineTranslateSwitchCell.lu.reuseIdentifier,
            title: BundleI18n.LarkMine.Lark_NewSettings_AutoTranslation,
            status: isFinalOpen,
            switchHandler: { [weak self] isOpen in
                guard let self = self else { return }
                /// 更新自动翻译一级总开关
                self.updateAutoTranslateGlobalSwitch(isOpen: isOpen)
                let action = isOpen ? TranslateActionStatus.open : TranslateActionStatus.close
                MineTracker.trackAutoTranslateSetting(action: action, position: .global_setting, object: .general)
                // 视频会议会中聊天开关变更埋点
                let isVCIMOpen = (self.currGloabalScopes & Im_V1_TranslateScopeMask.videoConference.rawValue != 0)
                if isVCIMOpen != isOpen {
                    MineTracker.trackVCAutoTranslateSetting(isOn: isOpen)
                }
            })
        self.autoTranslateItems.append(autoTranslateItem)
        if !isFinalOpen {
            return self.autoTranslateItems
        }

        scopeTitles.forEach { (scope, title) in
            let isSelected = (scopes & scope) != 0
            let disAutoTranslateLanguages = self.getDisAutoTranslateListText(scope: Int32(scope))
            MineTranslateSettingViewModel.logger.debug("translate: translateScope = \(self.userGeneralSettings.translateLanguageSetting.translateScope), scopes = \(scopes) ")
            MineTranslateSettingViewModel.logger.debug("translate: disAutoTranslateLanguages = \(disAutoTranslateLanguages), scope = \(scope)")
            let item = MineTranslateCheckboxModel(
                cellIdentifier: MineTranslateCheckboxCell.lu.reuseIdentifier,
                title: title,
                detail: disAutoTranslateLanguages,
                status: isSelected,
                switchHandler: { [weak self] isSelected in
                    guard let `self` = self else { return }
                    self.currGloabalScopes += isSelected ? scope : -scope
                    self.setGlobalTranslateScopes(scopes: self.currGloabalScopes, scope: scope, isOn: isSelected)
                    MineTranslateSettingViewModel.logger.debug("global scopes switch currGloabalScopes = \(self.currGloabalScopes), scope = \(scope)")
                    self.trackScopeSwitch(scope: scope, isOn: isSelected, isGenenalOpen: isFinalOpen)
                })
            self.autoTranslateItems.append(item)
        }

        /// 按语言设置
        let languageItem = MineTranslateTitleModel(
            cellIdentifier: MineTranslateTitleCell.lu.reuseIdentifier,
            title: BundleI18n.LarkMine.Lark_NewSettings_AutoTranslationSetByLanguage,
            tapHandler: { [weak self] in
                guard let `self` = self else { return }
                self.router.pushLanguagesListSettingController(currGloabalScopes: self.currGloabalScopes, detailModelType: .translateScopes)
            })
        self.autoTranslateItems.append(languageItem)
        return self.autoTranslateItems
    }

    /// 创建头部视图
    private func createHeaderViews() -> [() -> UIView] {
        func createNormalHeaderView(title: String) -> UIView {
            let view = UIView()
            let topMagin = title.isEmpty ? 8 : 14
            let bottomMagin = title.isEmpty ? 0 : -2
            let detailLabel = UILabel()
            detailLabel.font = UIFont.systemFont(ofSize: 14)
            detailLabel.numberOfLines = 0
            detailLabel.textColor = UIColor.ud.textPlaceholder
            detailLabel.text = title
            view.addSubview(detailLabel)
            detailLabel.snp.makeConstraints { (make) in
                make.top.equalTo(topMagin)
                make.bottom.equalTo(bottomMagin)
                make.left.equalTo(16)
                make.right.equalTo(-16)
            }
            return view
        }

        var tempHeaderViews: [() -> UIView] = []
        /// section 0 内容翻译成
        tempHeaderViews.append {
            return createNormalHeaderView(title: "")
        }
        /// section 1 内容翻译后的效果
        tempHeaderViews.append {
            return createNormalHeaderView(title: BundleI18n.LarkMine.Lark_NewSettings_TranslationDisplay)
        }
        /// section 2 自动翻译以下内容 付费租户才可见
        if self.isEnableAutoTranslation {
            tempHeaderViews.append {
                return createNormalHeaderView(title: "")
            }
        }
        return tempHeaderViews
    }

    /// 创建尾部视图
    private func createFooterViews() -> [() -> UIView] {
        var tempFooterViews: [() -> UIView] = []
        /// section 0 内容翻译成
        tempFooterViews.append {
            let view = UIView()
            view.snp.makeConstraints { $0.height.equalTo(1) }
            return view
        }
        /// section 1 翻译显示效果
        if self.isEnableAutoTranslation {
            tempFooterViews.append {
                let view = UIView()
                view.snp.makeConstraints { $0.height.equalTo(1) }
                return view
            }
        }
        /// section 2 自动翻译
        if self.isEnableAutoTranslation, self.userGeneralSettings.translateLanguageSetting.messageSwitch {
            tempFooterViews.append {
                let view = UIView()
                view.snp.makeConstraints { $0.height.equalTo(1) }
                return view
            }
        }
        return tempFooterViews
    }

    /// 设置全局翻译scopes
    /// - Parameter scopes: 修改后设置的scopes
    /// - Parameter scope: 修改的scope
    /// - Parameter isOn: 修改的scope的状态
    private func setGlobalTranslateScopes(scopes: Int, scope: Int, isOn: Bool) {
        MineTranslateSettingViewModel.logger.debug("translate: setGlobalTranslateScopes scopes = \(scopes)")
        self.userGeneralSettings.updateAutoTranslateScope(scope: scopes).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.metricLogger.log(metric: BusinessID.Settings.AutoTranslateSetting.setSecondaryAutoTranslateSwitch,
                                       params: ["type": "\(scope)", "switch": (isOn ? "true" : "false")])
                }, onError: { [weak self] error in
                    guard let window = self?.targetVC?.view.window else { return }
                    UDToast.showTips(with: BundleI18n.LarkMine.Lark_Legacy_MineMessageSettingSetupFailed, on: window)
                    self?.metricLogger.log(metric: BusinessID.Settings.AutoTranslateSetting.setSecondaryAutoTranslateSwitchFailed,
                                           error: error)
            }).disposed(by: self.disposeBag)
    }

    /// 更新自动翻译一级总开关
    private func updateAutoTranslateGlobalSwitch(isOpen: Bool) {
        self.userGeneralSettings.setAutoTranslateGlobalSwitch(isOpen: isOpen)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.metricLogger.log(metric: BusinessID.Settings.AutoTranslateSetting.setSpecificAutoTranslateSwitch, params: ["switch": (isOpen ? "true" : "false")])
            }, onError: { [weak self] error in
                guard let window = self?.targetVC?.view.window else { return }
                UDToast.showTips(with: BundleI18n.LarkMine.Lark_Legacy_MineMessageSettingSetupFailed,
                                    on: window)
                self?.metricLogger.log(metric: BusinessID.Settings.AutoTranslateSetting.setSpecificAutoTranslateSwitchFailed, error: error)
            }).disposed(by: self.disposeBag)
    }

    /// 修改全局翻译效果, 新版本仅用于修改global_conf
    private func updateGlobalConf(globalConf: RustPB.Im_V1_LanguagesConfiguration) {
        let onlyTranslation = globalConf.rule == .onlyTranslation
        self.userGeneralSettings.updateGlobalLanguageDisplayConfig(globalConf: globalConf)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                // update settings from server
                self.userGeneralSettings.fetchTranslateLanguageSetting(strategy: .forceServer)
                    .subscribe()
                    .disposed(by: self.disposeBag)
                self.metricLogger.log(metric: BusinessID.Settings.DisplayEffectSetting.setGlobalDisplayRule,
                                      params: [" display_type": (onlyTranslation ? "1" : "2")])
                }, onError: { [weak self] error in
                    guard let window = self?.targetVC?.view.window else { return }
                    UDToast.showTips(with: BundleI18n.LarkMine.Lark_Legacy_MineMessageSettingSetupFailed,
                                        on: window)
                    self?.metricLogger.log(metric: BusinessID.Settings.DisplayEffectSetting.setGlobalDisplayRule,
                                           error: error)
            }).disposed(by: self.disposeBag)
    }

    /// 内容翻译的目标语言
    private func getTranslateLanguageValue() -> String {
        let targetLanguage = self.userGeneralSettings.translateLanguageSetting.targetLanguage
        let trgLanguagesConfig = self.userGeneralSettings.translateLanguageSetting.trgLanguagesConfig[targetLanguage]
        let languageValue = trgLanguagesConfig?.language ?? ""
        return languageValue
    }

    /// 得到当前用户选中的语言key对应的内容
    func disableAutoTranslateLanguageValues(scope: Int32) -> [String] {
        let currGloabalScopes = Int32(self.currGloabalScopes)
        let globalScopeIsOpen = (currGloabalScopes & scope) != 0
        MineTranslateSettingViewModel.logger.debug("translate: disables currGloabalScopes = \(currGloabalScopes), globalScopeIsOpen = \(globalScopeIsOpen)")
        /// 该scope被关闭的语言
        let srcLanguagesConfig = self.userGeneralSettings.translateLanguageSetting.srcLanguagesConfig
        var noTranslateDic: [String: Im_V1_SrcLanguageConfig] = [:]
        var noTranslateLanguages: [String] = []
        for (languageName, value) in srcLanguagesConfig {
            let isScopeIsDisabled = (value.scopes & scope) == 0
            let shouldAdd = globalScopeIsOpen && isScopeIsDisabled
            if shouldAdd {
                noTranslateDic[languageName] = value
            }
        }
        if noTranslateDic.values.count == srcLanguagesConfig.values.count {
            return []
        }
        for languageName in userGeneralSettings.translateLanguageSetting.srcLanugages {
            guard let value = noTranslateDic[languageName],
                  let language = value.i18NLanguage[LanguageManager.currentLanguage.localeIdentifier.lowercased()] ?? value.i18NLanguage[value.defaultLocale.lowercased()] else {
                continue
            }
            noTranslateLanguages.append(language)
        }
        MineTranslateSettingViewModel.logger.debug("translate: disable languages",
                                                      additionalData: ["tempLanguageValues": "\(noTranslateLanguages)",
                                                        "globalScopeIsOpen": "\(globalScopeIsOpen)",
                                                        "currGloabalScopes": "\(currGloabalScopes)"
        ])
        return noTranslateLanguages
    }

    /// 埋点
    func trackScopeSwitch (scope: Int, isOn: Bool, isGenenalOpen: Bool) {
        let action = isOn ? TranslateActionStatus.open : TranslateActionStatus.close
        let generalType = isGenenalOpen ? TranslateGeneralStatusType.general_open : TranslateGeneralStatusType.general_open
        let translateActionStatus = isOn ? TranslateActionStatus.open : TranslateActionStatus.close

        var objectType: TranslateSettingObjectType = .unknow
        if scope == RustPB.Im_V1_TranslateScopeMask.larkMessageMask.rawValue {
            objectType = .message
        } else if scope == RustPB.Im_V1_TranslateScopeMask.docCommentMask.rawValue {
            objectType = .comment
        } else if scope == RustPB.Im_V1_TranslateScopeMask.docBodyMask.rawValue {
            objectType = .doc
        } else if scope == RustPB.Im_V1_TranslateScopeMask.webXml.rawValue {
            objectType = .web
            MineTracker.trackWebAutoTranslateSetting(action: translateActionStatus, position: TranslateSettingPositionType.global_setting)
        } else if scope == RustPB.Im_V1_TranslateScopeMask.email.rawValue {
            objectType = .email
        } else if scope == RustPB.Im_V1_TranslateScopeMask.videoConference.rawValue {
            // 视频会议聊天自动翻译功能开关点击事件埋点
            MineTracker.trackVCAutoTranslateSetting(isOn: isOn)
            return
        } else if scope == RustPB.Im_V1_TranslateScopeMask.moments.rawValue {
            objectType = .moments
        }
        MineTracker.trackAutoTranslateSetting(action: action, position: .global_setting, object: objectType, general: generalType)
    }

}

extension MineTranslateSettingViewModel {

    /// 获取禁用自动翻译语言列表文案
    func getDisAutoTranslateListText(scope: Int32) -> String {
        let disableLanguages = disableAutoTranslateLanguageValues(scope: scope)
        if disableLanguages.isEmpty { return "" }

        var disAutoTranslateText = ""
        let separator = LanguageManager.currentLanguage == .en_US ? "," : "、"
        disableLanguages.forEach { (srcLanugage) in
            disAutoTranslateText += srcLanugage + ((srcLanugage == disableLanguages.last) ? "" : separator)
        }
        return BundleI18n.LarkMine.Lark_Chat_ExceptRule(disAutoTranslateText)
    }

    /// 获取翻译效果的原文
    func getTranlateOriginDoc(targetLanguage: String) -> String {
        let translateLanguageSetting = self.userGeneralSettings.translateLanguageSetting
        var orignDoc: String?
        /// 示意图中译文的语种根据用户当前的语言设置来刷新，即当用户目标语种为英文时，示意图中都是翻译为英文
        let currLanguagePrefix = LanguageManager.currentLanguage.languageCode ?? ""
        switch LanguageManager.currentLanguage {
        case .zh_CN:
            //  1. 在中文客户端下，用户把目标语种改成了英文，则此时原文就变为中文
            let languagePrefixEnUs = Lang.en_US.languageCode ?? ""
            if targetLanguage == languagePrefixEnUs {
                orignDoc = translateLanguageSetting.trgLanguagesConfig[currLanguagePrefix]?.translationDoc
            } else {
                // 中文和日文客户端下，原文是英文
                orignDoc = translateLanguageSetting.trgLanguagesConfig[languagePrefixEnUs]?.translationDoc
            }
        case .en_US:
            //  2. 在英文客户端下，用户把目标语种改为了中文，则此时原文就变为英文
            let languagePrefixZhCn = Lang.zh_CN.languageCode ?? ""
            if targetLanguage == languagePrefixZhCn {
                orignDoc = translateLanguageSetting.trgLanguagesConfig[currLanguagePrefix]?.translationDoc
            } else {
                // 英文客户端下，原文是中文
                orignDoc = translateLanguageSetting.trgLanguagesConfig[languagePrefixZhCn]?.translationDoc
            }
        case .ja_JP:
            //  3. 在日文客户端下，用户把目标语种改为了英文，则此时原文就变为日文
            let languagePrefixEnUs = Lang.en_US.languageCode ?? ""
            if targetLanguage == languagePrefixEnUs {
                orignDoc = translateLanguageSetting.trgLanguagesConfig[currLanguagePrefix]?.translationDoc
            } else {
                // 中文和日文客户端下，原文是英文
                orignDoc = translateLanguageSetting.trgLanguagesConfig[languagePrefixEnUs]?.translationDoc
            }
        default:
            orignDoc = BundleI18n.LarkMine.Lark_NewSettings_TranslationDisplaySampleZh
        }

        let finalOrignDoc = orignDoc ?? BundleI18n.LarkMine.Lark_NewSettings_TranslationDisplaySampleZh
        MineTranslateSettingViewModel.logger.debug("translate: getTranlateOriginDoc",
                                                      additionalData: ["orignDoc": finalOrignDoc,
                                                        "targetLanguage": targetLanguage,
                                                        "currLanguageName": currLanguagePrefix])
        return finalOrignDoc
    }

}
