//
//  ChatTranslateSettingViewController.swift
//  LarkChatSetting
//
//  Created by bytedance on 3/23/22.
//

import Foundation
import UIKit
import FigmaKit
import RxSwift
import LarkUIKit
import LKCommonsTracker
import UniverseDesignToast
import LarkMessengerInterface
import EENavigator

final class ChatTranslateSettingViewController: BaseSettingController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    private let disposeBag = DisposeBag()
    private let tableView = InsetTableView(frame: .zero)
    private var viewModel: ChatTranslateSettingViewModel

    init(viewModel: ChatTranslateSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.targetVC = self
        configViewModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        commInit()
    }
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }
    private func commInit() {
        view.backgroundColor = UIColor.ud.bgFloatBase
        commInitNavi()
        commTableView()
    }
    private func commInitNavi() {
        title = BundleI18n.LarkChatSetting.Lark_IM_TranslationAssistantSettings_Title
    }
    private func commTableView() {
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 66
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        self.view.addSubview(tableView)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.frame = self.view.bounds
        tableView.lu.register(cellSelf: ChatInfoToTopCell.self)
        tableView.lu.register(cellSelf: ChatInfoNickNameCell.self)

        tableView.register(
            GroupSettingSectionView.self,
            forHeaderFooterViewReuseIdentifier: String(describing: GroupSettingSectionView.self))
        tableView.register(
            GroupSettingSectionEmptyView.self,
            forHeaderFooterViewReuseIdentifier: String(describing: GroupSettingSectionEmptyView.self))
        tableView.register(GroupSettingClickableSectionView.self, forHeaderFooterViewReuseIdentifier: String(describing: GroupSettingClickableSectionView.self))
        tableView.register(
            UITableViewHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: "UITableViewHeaderFooterView")
    }
    private func configViewModel() {
        viewModel.reloadData
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.tableView.reloadData()
            }).disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        tableView.reloadData()
    }
    // MARK: - UITableViewDelegate
//     swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: GroupSettingSectionEmptyView.self))
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: GroupSettingClickableSectionView.self)) as? GroupSettingClickableSectionView else {
            return tableView.dequeueReusableHeaderFooterView(
                withIdentifier: String(describing: GroupSettingSectionEmptyView.self))
        }
        footer.setTitleTopMargin(4)
        if let attrTitle = viewModel.items.sectionFooter(at: section) {
            footer.titleTextView.isHidden = false
            footer.titleTextView.attributedText = attrTitle
            footer.titleTextView.delegate = self
            return footer
        }

        footer.titleTextView.isHidden = true
        return footer
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.items.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = viewModel.items.item(at: indexPath),
           var cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? CommonCellProtocol {
            cell.updateAvailableMaxWidth(self.view.bounds.width)
            cell.item = item
            if let cell = cell as? UITableViewCell {
                return cell
            }
            return UITableViewCell()
        }
        return UITableViewCell()
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.absoluteString == self.viewModel.clickDescriptionOfChatInfoAutoTranslateModelURL {
            self.viewModel.navigator.push(body: TranslateSettingBody(), from: self)
            return false
        }
        return true
    }
}
