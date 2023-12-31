//
//  MineTranslateLanguageListViewModel.swift
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
import LarkContainer
import RustPB

/// 翻译语言列表vm
final class MineTranslateLanguageListViewModel {
    private let disposeBag = DisposeBag()
    private static let logger = Logger.log(MineTranslateLanguageListViewModel.self, category: "TranslateLanguage")
    let userResolver: UserResolver
    let userNavigator: Navigatable
    /// 用户常用设置
    let userGeneralSettings: UserGeneralSettings
    var detailModelType: DetailModelType = .translateStyleEffect
    var currGloabalScopes: Int?
    /// 刷新表格视图
    private let refreshPublish = PublishSubject<Void>()
    private(set) var headerViews: [() -> UIView] = []

    /// 数据源
    private(set) var items: [MineTranslateLanguageModel] = []
    private(set) var searchResultItems: [MineTranslateLanguageModel] = []
    var refreshDriver: Driver<()> {
        return refreshPublish.asDriver(onErrorJustReturn: ())
    }

    init(userResolver: UserResolver,
        userNavigator: Navigatable,
        userGeneralSettings: UserGeneralSettings,
         currGloabalScopes: Int? = nil,
         detailModelType: DetailModelType) {
        self.userResolver = userResolver
        self.userNavigator = userNavigator
        self.userGeneralSettings = userGeneralSettings
        self.detailModelType = detailModelType
        self.currGloabalScopes = currGloabalScopes
        /// 设置初始值
        self.items = self.createDataSource()
        self.headerViews = self.createHeaderViews()
        /// 监听信号
        self.userGeneralSettings.translateLanguageSettingDriver
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.items = self.createDataSource()
                self.searchResultItems = self.createDataSource()
                self.refreshPublish.onNext(())
            }).disposed(by: self.disposeBag)
    }

    /// 创建数据源
    private func createDataSource() -> [MineTranslateLanguageModel] {
        var tempItems: [MineTranslateLanguageModel] = []
        let srcLanguagesConfig = self.userGeneralSettings.translateLanguageSetting.srcLanguagesConfig
        self.userGeneralSettings.translateLanguageSetting.srcLanugages.forEach { srcLanugage in
            let scope = srcLanguagesConfig[srcLanugage]?.scopes ?? 0
            let configDescText = languageConfigDescText(scope: Int(scope))
            let isRuleWithOriginal = srcLanguagesConfig[srcLanugage]?.rule == .withOriginal
            let displayEffectText = isRuleWithOriginal
                ? BundleI18n.LarkMine.Lark_NewSettings_TranslationDisplayTranslationAndOriginal
                : BundleI18n.LarkMine.Lark_NewSettings_TranslationDisplayTranslationOnly
            let item = MineTranslateLanguageModel(
                cellIdentifier: MineTranslateLanguageCell.lu.reuseIdentifier,
                title: srcLanguagesConfig[srcLanugage]?.language ?? "",
                subTitle: srcLanguagesConfig[srcLanugage]?.i18NLanguage[LanguageManager.currentLanguage.localeIdentifier.lowercased()] ?? "",
                detail: (detailModelType == .translateStyleEffect) ? displayEffectText : configDescText,
                srcConfig: srcLanguagesConfig[srcLanugage],
                srcLanugage: srcLanugage
            )
            tempItems.append(item)
            MineTranslateLanguageListViewModel.logger.debug("translate: createDataSource",
                                                            additionalData: ["srcLanugage": "\(srcLanugage)",
                                                                "rule": "\(String(describing: srcLanguagesConfig[srcLanugage]?.rule))"])
        }
        return tempItems
    }

    func fetchTranslateServerLanguageSetting () {
        self.userGeneralSettings.fetchTranslateLanguageSetting(strategy: .forceServer).subscribe().disposed(by: self.disposeBag)
    }

    /// 获取语言配置描述
    func languageConfigDescText(scope: Int) -> String {
        var descText = ""
        var detailInfo: [String] = []
        let separator = LanguageManager.currentLanguage == .en_US ? "," : "、"
        // 配置项中所有可展示的选项
        let allDisplayTitle = MineTranslateScopeMappingModel.createScopeTitles(userResolver: self.userResolver, config: self.userGeneralSettings.translateLanguageSetting.translateScopeConfiguration)
        var enableItem = 0
        for (itemScope, _) in allDisplayTitle where (itemScope & scope) != 0 {
            let scopeIntToDisplayTextMap = MineTranslateScopeMappingModel.scopeIntToDisplayText(userResolver: userResolver)
            if let displayText = scopeIntToDisplayTextMap[itemScope] {
                detailInfo.append(displayText)
            }
            enableItem += 1
        }
        if detailInfo.isEmpty {
            //不可翻译
            return BundleI18n.LarkMine.Lark_Chat_Auto_Translation_Closed
        } else {
            if enableItem == allDisplayTitle.count && enableItem > 1 {
                return BundleI18n.LarkMine.Lark_Chat_Auto_Translation_All_Support
            } else {
                detailInfo.forEach { (element: String) in
                    descText += element + ((element == detailInfo.last) ? "" : separator)
                }
            }
        }
        return descText
    }

    func updateSearchResult(filterKey: String) {
        self.searchResultItems = getSearchResultDataByKey(filterKey: filterKey)
    }

    /// 获取搜索结果
    func getSearchResultDataByKey(filterKey: String) -> [MineTranslateLanguageModel] {
        let _filterKey = filterKey.lowercased()
        guard !_filterKey.isEmpty else {
            return self.items
        }
        let tempItems: [MineTranslateLanguageModel] = self.items.filter {
            $0.title.lowercased().contains(_filterKey) || $0.subTitle.lowercased().contains(_filterKey)
        }
        MineTranslateLanguageListViewModel.logger.debug("getSearchResultDataByKey",
                                                        additionalData: ["filterKey": filterKey,
                                                            "tempItems": "\(tempItems)"])
        return tempItems
    }

    /// 创建头部视图
    private func createHeaderViews() -> [() -> UIView] {
        func createNormalHeaderView(title: String) -> UIView {
            let view = UIView()
            let topMagin = title.isEmpty ? 0 : 6
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
        let title = (detailModelType == .translateStyleEffect)
            ? BundleI18n.LarkMine.Lark_NewSettings_SetByLanguageTranslationDisplayDescription
            : BundleI18n.LarkMine.Lark_NewSettings_SetByLanguageAutoTranslationTip
        tempHeaderViews.append {
            return createNormalHeaderView(title: title)
        }
        return tempHeaderViews
    }
}
