//
//  DisableAutoTranslateLanguagesSettingController.swift
//  LarkMine
//
//  Created by 李勇 on 2019/5/13.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import UniverseDesignToast

/// 不自动翻译语言设置
final class DisableAutoTranslateLanguagesSettingController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    /// 表格视图cell被点击后多少时间后再执行其他操作，给足时间展示cell被点击的背景色
    private static let tableDidSelectSpaceValue = 0.04
    private let viewModel: DisableAutoTranslateLanguagesViewModel
    /// 头部被选中语言列表
    private lazy var headerSelectView = TranslateLanguagesHeaderView()
    /// 表格视图
    private lazy var tableView = self.createTableView()
    private let disposeBag = DisposeBag()
    /// 右导航按钮
    private lazy var rightItem: LKBarButtonItem = {
        let rightItem = LKBarButtonItem(title: BundleI18n.LarkMine.Lark_Legacy_Completed)
        rightItem.setBtnColor(color: UIColor.ud.colorfulBlue)
        rightItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        rightItem.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        rightItem.button.isHidden = true
        return rightItem
    }()
    /// 适配转屏
    private var tableFooterLabel: UILabel?

    init(viewModel: DisableAutoTranslateLanguagesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkMine.Lark_Legacy_SelectLabel
        /// 添加头部视图
        self.headerSelectView.delegate = self
        self.view.addSubview(self.headerSelectView)
        self.headerSelectView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(self.viewModel.disableAutoTranslateLanguages.isEmpty ? 0 : 54)
        }
        let disableAutoLanguages = self.viewModel.disableAutoTranslateLanguageValues()
        self.headerSelectView.updateTranslateLanguages(languageKeys: disableAutoLanguages.0, languageValues: disableAutoLanguages.1)
        /// 添加表格视图
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.headerSelectView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        /// 设置右导航
        self.navigationItem.rightBarButtonItem = self.rightItem
        /// 刷新表格视图
        self.viewModel.reloadDataDriver.drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.headerSelectView.snp.updateConstraints({ (make) in
                make.height.equalTo(self.viewModel.disableAutoTranslateLanguages.isEmpty ? 0 : 54)
            })
            let disableAutoLanguages = self.viewModel.disableAutoTranslateLanguageValues()
            self.headerSelectView.updateTranslateLanguages(languageKeys: disableAutoLanguages.0, languageValues: disableAutoLanguages.1)
            self.tableView.reloadData()
        }).disposed(by: self.disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.resizeTableFooterView()
    }

    /// 创建表格视图
    private func createTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.ud.N50
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = self.createTableFooterView()
        tableView.tableHeaderView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0.1, height: 0.1)))
        tableView.estimatedRowHeight = 50
        tableView.sectionFooterHeight = 0
        tableView.sectionHeaderHeight = 8
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorColor = UIColor.ud.commonTableSeparatorColor
        tableView.backgroundColor = UIColor.ud.commonBackgroundColor
        tableView.lu.register(cellSelf: TranslateLanguagesCell.self)
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }

    /// 创建表格视图footer视图
    private func createTableFooterView() -> UIView {
        /// 文本
        let label: UILabel = UILabel()
        label.textColor = UIColor.ud.N500
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = BundleI18n.LarkMine.Lark_Chat_UntranslateLanguageTips
        self.tableFooterLabel = label
         let footerView = UIView()
        footerView.addSubview(label)
        return footerView
    }

    /// 计算TableFooter的大小
    private func resizeTableFooterView() {
        guard let label = self.tableFooterLabel, let tableFooter = self.tableView.tableFooterView else { return }
        let labelSize: CGSize = label.sizeThatFits(CGSize(width: self.view.frame.width - 32, height: 0))
        label.frame = CGRect(origin: CGPoint(x: 16, y: 3.5), size: labelSize)
        /// footer frame
        tableFooter.frame = CGRect(
            origin: .zero,
            size: CGSize(width: self.view.frame.width, height: labelSize.height + 3.5)
        )
        self.tableView.tableFooterView = tableFooter
    }

    @objc
    private func navigationBarRightItemTapped() {
        self.viewModel.requestDisableAutoTranslateLanguages().observeOn(MainScheduler.instance)
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
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.allNeedShowSupportedLanguages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        cell.set(title: languageValue, isSelected: self.viewModel.disableAutoTranslateLanguages.contains(languageKey))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        self.rightItem.button.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + DisableAutoTranslateLanguagesSettingController.tableDidSelectSpaceValue) {
            self.viewModel.handlerSelectLanguage(language: self.viewModel.allNeedShowSupportedLanguages[indexPath.row])
        }
    }
}

// MARK: - TranslateLanguagesHeaderViewDelegate
extension DisableAutoTranslateLanguagesSettingController: TranslateLanguagesHeaderViewDelegate {
    func languageKeyDidSelect(language: String) {
        self.rightItem.button.isHidden = false
        self.viewModel.handlerSelectLanguage(language: language)
    }
}
