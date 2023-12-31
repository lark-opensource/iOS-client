//
//  LanguagesConfigurationSettingController.swift
//  LarkMine
//
//  Created by 李勇 on 2019/5/13.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkModel
import UniverseDesignToast

/// 翻译效果高级设置，让某些语言不使用全局翻译效果
final class LanguagesConfigurationSettingController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    /// 表格视图cell被点击后多少时间后再执行其他操作，给足时间展示cell被点击的背景色
    private static let tableDidSelectSpaceValue = 0.04
    private let viewModel: LanguagesConfigurationSettingViewModel
    /// 表格视图
    private lazy var tableView = self.createTableView()
    private let disposeBag = DisposeBag()
    /// 右导航按钮
    private lazy var rightItem: LKBarButtonItem = {
        let rightItem = LKBarButtonItem(title: BundleI18n.LarkMine.Lark_Legacy_Completed)
        rightItem.setBtnColor(color: UIColor.ud.primaryContentDefault)
        rightItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        rightItem.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        rightItem.button.isHidden = true
        return rightItem
    }()

    init(viewModel: LanguagesConfigurationSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkMine.Lark_Chat_AdvancedSetting
        /// 添加表格视图
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }

        /// 设置右导航
        self.navigationItem.rightBarButtonItem = self.rightItem
        /// 刷新表格视图
        self.viewModel.reloadDataDriver.drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.tableView.reloadData()
        }).disposed(by: self.disposeBag)
    }

    /// 创建表格视图
    private func createTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0.1, height: 0.1)))
        tableView.tableHeaderView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0.1, height: 0.1)))
        tableView.estimatedRowHeight = 50
        tableView.estimatedSectionFooterHeight = 20
        tableView.estimatedSectionHeaderHeight = 20
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.backgroundColor = UIColor.clear
        tableView.lu.register(cellSelf: TranslateLanguagesCell.self)
        tableView.lu.register(cellSelf: TranslateSelectedLanguagesCell.self)
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }

    @objc
    private func navigationBarRightItemTapped() {
        self.viewModel.requestSetTranslateConfiguration().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.navigationController?.popViewController(animated: true)
            }, onError: { [weak self] _ in
                guard let `self` = self else { return }
                UDToast.showTips(
                    with: BundleI18n.LarkMine.Lark_Legacy_MineMessageSettingSetupFailed,
                    on: self.view
                )
            }).disposed(by: self.disposeBag)
    }
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.otherConfigurationLanguages.isEmpty ? 1 : 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        /// 语言列表
        if self.viewModel.otherConfigurationLanguages.isEmpty {
            return self.viewModel.allNeedShowSupportedLanguages.count
        }
        /// 选中语言 + 语言列表
        return section == 0 ? 1 : self.viewModel.allNeedShowSupportedLanguages.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        /// 请选择翻译后展示译文的语言
        if self.viewModel.otherConfigurationLanguages.isEmpty {
            let view = UIView()
            let label = UILabel()
            label.textColor = UIColor.ud.textPlaceholder
            label.font = UIFont.systemFont(ofSize: 14)
            label.text = BundleI18n.LarkMine.Lark_Chat_AdvancedSettingDescriptionMobile(self.viewModel.currConfigurationValue())
            label.numberOfLines = 0
            view.addSubview(label)
            label.snp.makeConstraints { (make) in
                make.bottom.equalTo(-2)
                make.top.equalTo(14)
                make.left.equalTo(16)
                make.right.equalTo(-16)
            }
            return view
        }
        /// 灰色
        let view = UIView()
        view.snp.makeConstraints { (make) in
            make.height.equalTo(section == 0 ? 14 : 1)
        }
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if self.viewModel.otherConfigurationLanguages.isEmpty {
            let view = UIView()
            view.snp.makeConstraints { (make) in
                make.height.equalTo(1)
            }
            return view
        }
        /// 以上语言的内容翻译后展示译文
        if section == 0 {
            let view = UIView()
            let label = UILabel()
            label.textColor = UIColor.ud.textPlaceholder
            label.text = BundleI18n.LarkMine.Lark_Chat_AdvancedSettingDescription(self.viewModel.currConfigurationValue())
            label.font = UIFont.systemFont(ofSize: 14)
            label.numberOfLines = 0
            view.addSubview(label)
            label.snp.makeConstraints { (make) in
                make.bottom.equalTo(-14)
                make.top.equalTo(2)
                make.left.equalTo(16)
                make.right.equalTo(-16)
            }
            return view
        }
        let view = UIView()
        view.snp.makeConstraints { (make) in
            make.height.equalTo(1)
        }
        return view
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /// 选中的所有语言cell
        if !self.viewModel.otherConfigurationLanguages.isEmpty, indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TranslateSelectedLanguagesCell.lu.reuseIdentifier) as? TranslateSelectedLanguagesCell else {
                return UITableViewCell()
            }
            cell.delegate = self
            let disableAutoLanguages = self.viewModel.currConfigurationLanguageValues()
            cell.updateTranslateLanguages(languageKeys: disableAutoLanguages.0, languageValues: disableAutoLanguages.1)
            return cell
        }
        /// 语言列表
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TranslateLanguagesCell.lu.reuseIdentifier) as? TranslateLanguagesCell else {
            return UITableViewCell()
        }
        guard indexPath.row < self.viewModel.allNeedShowSupportedLanguages.count else {
            return UITableViewCell()
        }
        let languageKey = self.viewModel.allNeedShowSupportedLanguages[indexPath.row]
        guard let languageValue = self.viewModel.userGeneralSettings.translateLanguageSetting.supportedLanguages[languageKey] else {
            return UITableViewCell()
        }
        cell.set(title: languageValue, isSelected: self.viewModel.otherConfigurationLanguages.contains(languageKey))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        /// 点击选中的语言cell，不做任何操作
        if !self.viewModel.otherConfigurationLanguages.isEmpty, indexPath.section == 0 { return }

        self.rightItem.button.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + LanguagesConfigurationSettingController.tableDidSelectSpaceValue) {
            self.viewModel.handlerSelectLanguage(language: self.viewModel.allNeedShowSupportedLanguages[indexPath.row])
        }
    }
}

// MARK: - TranslateSelectedLanguages
extension LanguagesConfigurationSettingController: TranslateSelectedLanguages {
    func languageKeyDidSelect(language: String) {
        self.rightItem.button.isHidden = false
        self.viewModel.handlerSelectLanguage(language: language)
    }
}
