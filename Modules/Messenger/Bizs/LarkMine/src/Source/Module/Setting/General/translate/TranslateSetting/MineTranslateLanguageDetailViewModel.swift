//
//  MineTranslateLanguageDetailController.swift
//  LarkMine
//
//  Created by zhenning on 2020/02/11.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkSDKInterface
import UniverseDesignToast
import LKCommonsLogging
import LarkContainer
import LKMetric
import RustPB

enum DetailModelType: Int {
    /// 翻译效果展示
    case translateStyleEffect = 1
    /// 翻译scope设置
    case translateScopes = 2
}

final class MineTranslateLanguageDetailViewModel {
    private let disposeBag = DisposeBag()
    private static let logger = Logger.log(MineTranslateLanguageDetailViewModel.self, category: "TranslateLanguage")
    let metricLogger = MineMetric()

    weak var targetVC: UIViewController?

    /// 刷新表格视图
    private let refreshPublish = PublishSubject<Void>()
    private(set) var headerViews: [() -> UIView] = []
    let userResolver: UserResolver
    var userGeneralSettings: UserGeneralSettings
    var srcLanguageModel: MineTranslateLanguageModel
    /// 是否是翻译效果
    var detailModelType: DetailModelType = .translateStyleEffect
    var isDisplayRule: Bool {
        return detailModelType == .translateStyleEffect
    }
    var currGloabalScopes: Int?
    private var selectedRadioItem: MineTranslateRadioModel?
    /// 当前设置的翻译scope
    private var currentTranslateScopes: Int = 0

    /// 数据源
    var items: [MineTranslateItemProtocol] {
        return self.isDisplayRule ? self.effectRuleItems : self.scopesConfigItems
    }
    /// 翻译效果规则
    var effectRuleItems: [MineTranslateRadioModel] = []
    /// 翻译配置Scope
    var scopesConfigItems: [MineTranslateSwitchModel] = []
    var refreshDriver: Driver<()> {
        return refreshPublish.asDriver(onErrorJustReturn: ())
    }

    init(userResolver: UserResolver,
         userGeneralSettings: UserGeneralSettings,
         srcLanguageModel: MineTranslateLanguageModel,
         currGloabalScopes: Int?,
         detailModelType: DetailModelType) {
        self.userResolver = userResolver
        self.userGeneralSettings = userGeneralSettings
        self.srcLanguageModel = srcLanguageModel
        self.detailModelType = detailModelType
        self.currGloabalScopes = currGloabalScopes
        /// 设置初始值
        self.createDataSource()
        if let selectedRadioItem = self.items.first(where: {
            if let item = $0 as? MineTranslateRadioModel {
                return item.status == true
            } else {
                return false
            }
        }) as? MineTranslateRadioModel {
            self.selectedRadioItem = selectedRadioItem
        }

        self.userGeneralSettings.translateLanguageSettingDriver
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.createDataSource()
                self.refreshPublish.onNext(())
            }).disposed(by: self.disposeBag)

        self.headerViews = self.createHeaderViews()

        if isDisplayRule {
            /// 打开设置特定语言翻译效果页面
            if self.srcLanguageModel.srcConfig == nil {
                self.metricLogger.log(metric: BusinessID.Settings.DisplayEffectSetting.openSpecificDisplayPageFailed)
            } else {
                self.metricLogger.log(metric: BusinessID.Settings.DisplayEffectSetting.openSpecificDisplayPage)
            }
        } else {
            /// 打开特定语言自动翻译页面
            if self.currGloabalScopes == nil {
                self.metricLogger.log(metric: BusinessID.Settings.AutoTranslateSetting.openOpecificAutoTranslatePageFailed)
            } else {
                self.metricLogger.log(metric: BusinessID.Settings.AutoTranslateSetting.openOpecificAutoTranslatePage)
            }
        }
    }

    /// 创建数据源
    private func createDataSource() {
        if self.isDisplayRule {
            let isRuleWithOriginal = self.srcLanguageModel.srcConfig?.rule == .withOriginal
            var tempItems: [MineTranslateRadioModel] = []
            // 显示原文和译文
            let originalAndTranslationItem = MineTranslateRadioModel(
                cellIdentifier: MineTranslateRadioCell.lu.reuseIdentifier,
                title: BundleI18n.LarkMine.Lark_NewSettings_TranslationDisplayTranslationAndOriginal,
                status: isRuleWithOriginal,
                translateDisplayRule: .withOriginal,
                isRadioLeft: true,
                tapHandler: { [weak self] in
                    self?.selectDisplayRule(translateDisplayRule: .withOriginal)
                }
            )

            let onlyTranslationItem = MineTranslateRadioModel(
                cellIdentifier: MineTranslateRadioCell.lu.reuseIdentifier,
                title: BundleI18n.LarkMine.Lark_NewSettings_TranslationDisplayTranslationOnly,
                status: !isRuleWithOriginal,
                translateDisplayRule: .onlyTranslation,
                isRadioLeft: true,
                tapHandler: { [weak self] in
                    self?.selectDisplayRule(translateDisplayRule: .onlyTranslation)
                }
            )

            tempItems.append(originalAndTranslationItem)
            tempItems.append(onlyTranslationItem)
            self.effectRuleItems = tempItems
        } else {
            var tempItems: [MineTranslateSwitchModel] = []
            let scopes = self.userGeneralSettings.translateLanguageSetting.getTranslateScope(srcLanguageKey: srcLanguageModel.srcLanugage)
            let config = self.userGeneralSettings.translateLanguageSetting.translateScopeConfiguration
            let scopeTitles: [(Int, String)] = MineTranslateScopeMappingModel.createScopeTitles(userResolver: self.userResolver, config: config)
            self.currentTranslateScopes = 0
            scopeTitles.forEach { (scope, title) in
                let isOpen = (scopes & scope) != 0
                let enabled = ((self.currGloabalScopes ?? 0) & scope) != 0
                let item = MineTranslateSwitchModel(
                    cellIdentifier: MineTranslateSwitchCell.lu.reuseIdentifier,
                    title: title,
                    status: isOpen,
                    enabled: enabled,
                    switchHandler: { [weak self] isOn in
                        guard let `self` = self else { return }
                        self.currentTranslateScopes += isOn ? scope : -scope
                        self.updateSrcLanguageScopes(scopes: self.currentTranslateScopes, scope: scope, isOn: isOn)
                        MineTranslateLanguageDetailViewModel.logger.debug("createDataSource currentTranslateScopes = \(self.currentTranslateScopes), scope = \(scope)")
                        self.trackScopeSwitch(scope: scope, isOn: isOn)
                    })
                MineTranslateLanguageDetailViewModel.logger.debug("createDataSource detailVM scopes = \(scopes), status = \(isOpen)")
                self.currentTranslateScopes += item.status ? scope : 0
                tempItems.append(item)
            }
            self.scopesConfigItems = tempItems
        }
    }

    func selectDisplayRule(translateDisplayRule: RustPB.Basic_V1_DisplayRule) {
        self.srcLanguageModel.srcConfig?.rule = translateDisplayRule
        var languagesConfig = RustPB.Im_V1_LanguagesConfiguration()
        languagesConfig.rule = translateDisplayRule
        self.userGeneralSettings.updateLanguagesConfigurationV2(srcLanguagesConf: [self.srcLanguageModel.srcLanugage: languagesConfig])
            .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (_) in
                // update settings from server
                self?.fetchTranslateServerLanguageSetting()

                let displayType = (translateDisplayRule == .onlyTranslation) ? 2 : 1
                self?.metricLogger.log(metric: BusinessID.Settings.DisplayEffectSetting.setSpecificDisplayRule,
                                       params: ["display_type": "\(displayType)", "language_key": self?.srcLanguageModel.srcLanugage ?? ""])
            }, onError: { [weak self] (error) in
                guard let window = self?.targetVC?.view.window else { return }
                UDToast.showTips(with: BundleI18n.LarkMine.Lark_Legacy_MineMessageSettingSetupFailed,
                                    on: window)
                self?.metricLogger.log(metric: BusinessID.Settings.DisplayEffectSetting.setSpecificDisplayRuleFailed, error: error)
            }).disposed(by: self.disposeBag)
        let defaultGlobal = (self.userGeneralSettings.translateLanguageSetting.globalConf.rule == .onlyTranslation)
            ? TranslateEffectType.onlyTranslation : TranslateEffectType.withOriginal
        let translateEffectType = (translateDisplayRule == .onlyTranslation) ? TranslateEffectType.onlyTranslation : TranslateEffectType.withOriginal
        MineTracker.trackTranslateEffectSpecialSetting(defaultGlobal: defaultGlobal, language: srcLanguageModel.srcLanugage, action: translateEffectType)
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
        /// section 0 按语言设置
        let title = (detailModelType == .translateStyleEffect)
            ? BundleI18n.LarkMine.Lark_Chat_SetTranslateStyleByLanguageDescription(self.srcLanguageModel.subTitle)
            : BundleI18n.LarkMine.Lark_Chat_SetAutoTranslateByLanguageDescription(self.srcLanguageModel.subTitle)
        tempHeaderViews.append {
            return createNormalHeaderView(title: title)
        }
        return tempHeaderViews
    }

    /// 设置源语言翻译设置scope
    /// - Parameter scopes: 修改后设置的scopes
    /// - Parameter scope: 修改的scope
    /// - Parameter isOn: 修改的scope的状态
    private func updateSrcLanguageScopes(scopes: Int, scope: Int, isOn: Bool) {
        self.srcLanguageModel.srcConfig?.scopes = Int32(scopes)
        MineTranslateLanguageDetailViewModel.logger.debug("check updateSrcLanguageScopes detailVM scopes = \(scopes), language = \(srcLanguageModel.srcLanugage)")
        self.userGeneralSettings.updateSrcLanguageScopes(srcLanguagesScope: scopes, language: srcLanguageModel.srcLanugage)
            .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                self?.metricLogger.log(metric: BusinessID.Settings.AutoTranslateSetting.setSpecificAutoTranslateSwitch,
                                       params: ["type": "\(scope)", "switch": (isOn ? "true" : "false")])
            }, onError: { [weak self] error in
                guard let window = self?.targetVC?.view.window else { return }
                UDToast.showTips(with: BundleI18n.LarkMine.Lark_Legacy_MineMessageSettingSetupFailed,
                                    on: window)
                self?.metricLogger.log(metric: BusinessID.Settings.AutoTranslateSetting.setSpecificAutoTranslateSwitchFailed,
                                       error: error)
            }).disposed(by: self.disposeBag)
    }

    /// 埋点
    func trackScopeSwitch (scope: Int, isOn: Bool) {
        let isGlobalScopeOpen = (self.userGeneralSettings.translateLanguageSetting.translateScope & scope) != 0
        let translateActionStatus = isOn ? TranslateActionStatus.open : TranslateActionStatus.close
        let defaultValueStatus = isGlobalScopeOpen ? TranslateActionStatus.open : TranslateActionStatus.close
        var object: TranslateSettingObjectType = .unknow
        if scope == RustPB.Im_V1_TranslateScopeMask.larkMessageMask.rawValue {
            object = .message
        } else if scope == RustPB.Im_V1_TranslateScopeMask.docCommentMask.rawValue {
            object = .comment
        } else if scope == RustPB.Im_V1_TranslateScopeMask.docBodyMask.rawValue {
            object = .doc
        } else if scope == RustPB.Im_V1_TranslateScopeMask.webXml.rawValue {
            object = .web
        } else if scope == RustPB.Im_V1_TranslateScopeMask.email.rawValue {
            object = .email
        } else if scope == RustPB.Im_V1_TranslateScopeMask.moments.rawValue {
            object = .moments
        }
        MineTracker.trackAutoTranslateSpecialSetting(object: object, language: self.srcLanguageModel.srcLanugage, action: translateActionStatus, defaultValueStatus: defaultValueStatus)
    }
}

extension MineTranslateLanguageDetailViewModel {
    func fetchTranslateServerLanguageSetting () {
        self.userGeneralSettings.fetchTranslateLanguageSetting(strategy: .forceServer).subscribe().disposed(by: self.disposeBag)
    }
}
