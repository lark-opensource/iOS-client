//
//  TranslateTagetLanguageSettingController.swift
//  Pods
//
//  Created by 李勇 on 2019/5/13.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LKCommonsLogging
import UniverseDesignToast
import LarkSDKInterface
import LarkSetting
import LarkContainer
import LarkLocalizations
import LKMetric
import FigmaKit

/// 翻译目标语言设置
final class TranslateTagetLanguageSettingController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    /// 表格视图cell被点击后多少时间后再执行其他操作，给足时间展示cell被点击的背景色
    private static let tableDidSelectSpaceValue = 0.04
    private let userResolver: UserResolver
    private let userGeneralSettings: UserGeneralSettings
    private var translateSettingsMainFGEnable = false
    let metricLogger = MineMetric()

    private static var logger = Logger.log(
        TranslateTagetLanguageSettingController.self,
        category: "Mine.Setting.Translate.TagetLanguage")

    private let disposeBag = DisposeBag()
    private lazy var tableView = self.createTableView()
    private lazy var rightItem: LKBarButtonItem = {
        let rightItem = LKBarButtonItem(title: BundleI18n.LarkMine.Lark_Legacy_Completed)
        rightItem.setBtnColor(color: UIColor.ud.primaryContentDefault)
        rightItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        rightItem.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        rightItem.button.isHidden = true
        return rightItem
    }()
    /// 数据源，里面只存了语言key
    private var dataSource: [String] = []
    /// 数据源，存放语言Model
    private var trgLanguageModels: [MineTranslateRadioModel] = []
    /// 当前用户选中的翻译目标语言，保证是dataSource中值
    private var currSelectLanguage: String = ""

    init(userResolver: UserResolver,
        userGeneralSettings: UserGeneralSettings) {
        self.userResolver = userResolver
        self.userGeneralSettings = userGeneralSettings
        super.init(nibName: nil, bundle: nil)
        let featureGatingService = try? self.userResolver.resolve(assert: FeatureGatingService.self)
        self.translateSettingsMainFGEnable = featureGatingService?.staticFeatureGatingValue(with: .translateSettingsV2Enable) ?? false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkMine.Lark_NewSettings_TranslateContentInto
        /// 添加表格视图
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }

        /// 新版设置项点击即触发保存，不需要完成步骤
       if !self.translateSettingsMainFGEnable {
           /// 设置右导航
           self.navigationItem.rightBarButtonItem = self.rightItem
       }
        /// 实时获取最新的数据
        self.setTranslateLanguageSettingDriver()
    }

    /// 创建表格视图
    private func createTableView() -> UITableView {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.estimatedRowHeight = 52
        tableView.sectionFooterHeight = 0
        tableView.sectionHeaderHeight = 8
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.lu.register(cellSelf: TranslateTagetLanguageCell.self)
        tableView.lu.register(cellSelf: MineTranslateCheckListBoxCell.self)
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }

    /// 实时获取最新的数据
    private func setTranslateLanguageSettingDriver() {
        self.userGeneralSettings.translateLanguageSettingDriver
            .drive(onNext: { [weak self] (setting) in
                guard let `self` = self else { return }
                /// 默认选择服务器返回的targetLanguage
                self.currSelectLanguage = setting.targetLanguage
                /// 重新构造数据源
                var tempDataSource: [String] = []
                var tempLanguageDataSource: [MineTranslateRadioModel] = []
                setting.languageKeys.forEach({ languageKey in
                    if self.translateSettingsMainFGEnable {
                        /// 必须要是服务器支持的语言
                        guard setting.trgLanguagesConfig.keys.contains(languageKey) else { return }
                        let trgLanguageMap = self.userGeneralSettings.translateLanguageSetting.trgLanguagesConfig.first(where: { $0.key == languageKey })
                        guard let languageName = trgLanguageMap?.value.language else {
                            return
                        }
                        let model = MineTranslateRadioModel(cellIdentifier: MineTranslateCheckListBoxCell.lu.reuseIdentifier,
                                                            title: languageName,
                                                            languageKey: languageKey,
                                                            status: languageKey == self.currSelectLanguage,
                                                            tapHandler: {})
                        tempLanguageDataSource.append(model)
                        tempDataSource.append(languageKey)
                    } else {
                        /// 必须要是服务器支持的语言
                        guard setting.supportedLanguages.keys.contains(languageKey) else { return }
                        tempDataSource.append(languageKey)
                    }
                })
                self.trgLanguageModels = tempLanguageDataSource
                self.dataSource = tempDataSource

                /// 如果服务器返回的不是一个正确的key，我们需要修正
                if !self.dataSource.contains(self.currSelectLanguage) {
                    self.currSelectLanguage = ""
                    if let language = self.dataSource.first {
                        self.currSelectLanguage = language
                    }
                }
                self.tableView.reloadData()
            }).disposed(by: self.disposeBag)
    }

    @objc
    private func navigationBarRightItemTapped() {
        self.updateTranslateLanguageSetting(language: self.currSelectLanguage)
    }

    /// 更新当前的翻译目标语言
    private func updateTranslateLanguageSetting(language: String) {
        /// 为了保险，我们再判断一次
        guard self.userGeneralSettings.translateLanguageSetting.supportedLanguages.keys.contains(language) else { return }

        self.userGeneralSettings.updateTranslateLanguageSetting(language: language)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.metricLogger.log(metric: BusinessID.Settings.TargetLanguageSetting.changeTargetLanguage, params: ["target_language": language])
                }, onError: { [weak self] (error) in
                    guard let window = self?.view.window else { return }
                    self?.metricLogger.log(metric: BusinessID.Settings.TargetLanguageSetting.changeTargetLanguageFailed,
                                           error: error)
                    TranslateTagetLanguageSettingController.logger.error("更改翻译语言设置失败", error: error)
                    UDToast.showTips(with: BundleI18n.LarkMine.Lark_Legacy_MineSettingTranslateError, on: window)
            }).disposed(by: self.disposeBag)
    }

    // MARK: - UITableViewDelegate & UITableViewDataSource

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.translateSettingsMainFGEnable ? self.trgLanguageModels.count : self.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let count = self.translateSettingsMainFGEnable ? self.trgLanguageModels.count : self.dataSource.count
        guard indexPath.row < count else {
            return UITableViewCell()
        }
        if self.translateSettingsMainFGEnable {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MineTranslateCheckListBoxCell.lu.reuseIdentifier) as? MineTranslateCheckListBoxCell else {
                return UITableViewCell()
            }
            cell.item = self.trgLanguageModels[indexPath.row]
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TranslateTagetLanguageCell.lu.reuseIdentifier) as? TranslateTagetLanguageCell else {
                return UITableViewCell()
            }
            let languageKey: String = self.dataSource[indexPath.row]
            guard let languageName: String = self.userGeneralSettings.translateLanguageSetting.supportedLanguages[languageKey] else {
                return UITableViewCell()
            }
            cell.set(title: languageName, isSelected: languageKey == self.currSelectLanguage)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        /// 重新设置用户选中的语言
        self.currSelectLanguage = self.dataSource[indexPath.row]
        let tempTrgLanguageModels = self.trgLanguageModels
        self.trgLanguageModels.removeAll()
        tempTrgLanguageModels.forEach {
            var model = $0
            model.status = ($0.languageKey == self.currSelectLanguage)
            self.trgLanguageModels.append(model)
        }
        if self.translateSettingsMainFGEnable {
            /// 新版设置项点击即触发保存，不需要完成步骤
            self.rightItem.button.isHidden = true
            self.updateTranslateLanguageSetting(language: self.currSelectLanguage)
        } else {
            self.rightItem.button.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + TranslateTagetLanguageSettingController.tableDidSelectSpaceValue) {
                tableView.reloadData()
            }
        }
        MineTracker.trackTranslateLanguageSetting(language: self.currSelectLanguage)
    }
}
