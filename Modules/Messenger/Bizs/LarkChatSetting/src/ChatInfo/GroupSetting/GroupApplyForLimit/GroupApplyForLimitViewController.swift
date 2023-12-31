//
//  GroupApplyForLimitViewComtroller.swift
//  LarkChatSetting
//
//  Created by bytedance on 2021/10/15.
//

import Foundation
import UIKit
import FigmaKit
import RxSwift
import RxCocoa
import LarkUIKit
import LKCommonsTracker
import UniverseDesignToast
import LarkCore
import LarkSDKInterface

protocol ScrollViewVCAvoidKeyboardProtocol: UIViewController {
    var actionScrollView: UIScrollView { get}
    var disposeBag: DisposeBag { get }
    var keyboardAvoidKeySpace: CGFloat { get }
    func observerKeyboardEvent()

}
extension ScrollViewVCAvoidKeyboardProtocol {

    var keyboardAvoidKeySpace: CGFloat { 75 }

    func observerKeyboardEvent() {
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] not in
                self?.keyboardWillAppear(not)
        })
        .disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] not  in
                self?.keyboardWillHide(not)
        })
        .disposed(by: disposeBag)
    }

    func keyboardWillAppear(_ notification: Notification) {
        if let keyboardBounds = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if let firstResponse = self.view.lu.firstResponder(),
               let superView = firstResponse.superview,
               let window = firstResponse.window {
                let frame = superView.convert(firstResponse.frame, to: window)
                let keyboardHeight = keyboardBounds.height
                let showWindowHeight = UIScreen.main.bounds.height - keyboardHeight
                let offset: CGFloat = keyboardAvoidKeySpace
                if frame.bottom + offset > showWindowHeight {
                    var contentOffset = actionScrollView.contentOffset
                    contentOffset.y += frame.bottom + offset - showWindowHeight
                    actionScrollView.setContentOffset(contentOffset, animated: true)
                }
            }
        }
    }

    private func keyboardWillHide(_ notification: Notification) {
        actionScrollView.setContentOffset(.zero, animated: true)
    }
}

final class GroupApplyForLimitViewController: BaseSettingController,
                                              UITableViewDelegate,
                                              UITableViewDataSource,
                                              ScrollViewVCAvoidKeyboardProtocol {
    var actionScrollView: UIScrollView { self.tableView }

    internal let disposeBag = DisposeBag()
    private let tableView = InsetTableView(frame: .zero)
    private var viewModel: GroupApplyForLimitViewModel
    private lazy var rightItem: LKBarButtonItem = {
        let item = LKBarButtonItem(title: BundleI18n.LarkChatSetting.Lark_GroupLimit_AppealGroupSize_SubmitButton, fontStyle: .medium)
        item.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        item.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        item.button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        item.addTarget(self, action: #selector(confirmSubmit), for: .touchUpInside)
        item.isEnabled = false
        return item
    }()

    init(viewModel: GroupApplyForLimitViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        configViewModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        commInit()
        viewModel.fetchData()
    }
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }
    private func commInit() {
        view.backgroundColor = UIColor.ud.bgFloatBase
        commInitNavi()
        commTableView()
        observerKeyboardEvent()
    }

    private func commInitNavi() {
        title = BundleI18n.LarkChatSetting.Lark_GroupLimit_GroupSizeAppeal_PageTitle
        navigationItem.rightBarButtonItem = rightItem
    }
    private func commTableView() {
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 66
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        self.view.addSubview(tableView)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.frame = self.view.bounds
        tableView.lu.register(cellSelf: ChatInfoNameCell.self)
        tableView.lu.register(cellSelf: GroupSettingInputCell.self)
        tableView.lu.register(cellSelf: GroupSettingTransferCell.self)
        tableView.lu.register(cellSelf: GroupSettingApproversCell.self)
        tableView.lu.register(cellSelf: GroupSettingSelectItemCell.self)
        tableView.register(
            GroupSettingSectionView.self,
            forHeaderFooterViewReuseIdentifier: String(describing: GroupSettingSectionView.self))
        tableView.register(
            GroupSettingSectionEmptyView.self,
            forHeaderFooterViewReuseIdentifier: String(describing: GroupSettingSectionEmptyView.self))
        tableView.register(
            UITableViewHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: "UITableViewHeaderFooterView")
    }

    private func configViewModel() {
        viewModel.controller = self
        viewModel.reloadData
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.tableView.reloadData()
            }).disposed(by: disposeBag)
        viewModel.getChat = { chat in
            Tracker.post(TeaEvent("im_chat_member_toplimit_apply_view", params: IMTracker.Param.chat(chat)))
        }
    }

    func setRightItemEnable(_ enable: Bool) {
        rightItem.isEnabled = enable
    }
    @objc
    func confirmSubmit() {
        viewModel.confirmSubmit { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(_):
                if let presentingVc = self.presentingViewController {
                    UDToast.showSuccess(with: BundleI18n.LarkChatSetting.Lark_GroupLimit_AppealSubmitted_Toast, on: presentingVc.view)
                }
                self.dismiss(animated: true, completion: nil)
            case .failure(let error):
                if let errorMsg = (error.underlyingError as? APIError)?.displayMessage,
                   !errorMsg.isEmpty {
                    UDToast.showFailure(with: errorMsg, on: self.view)
                }
            }
        }
    }

    // MARK: - UITableViewDelegate
//     swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: GroupSettingSectionView.self)) as? GroupSettingSectionView else {
            return tableView.dequeueReusableHeaderFooterView(
                withIdentifier: String(describing: GroupSettingSectionEmptyView.self))
        }
        if let title = viewModel.items.sectionHeader(at: section) {
            header.titleLabel.text = title
            header.titleLabel.isHidden = false
        } else {
            header.titleLabel.isHidden = true
        }

        header.touchesBeganCallBack = { [weak self] in
            self?.view.endEditing(false)
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard viewModel.items.sectionHeader(at: section) != nil else {
            return 16
        }
        return 36
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

    /// 拖动tableView的时候 收起键盘
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
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
                cell.isUserInteractionEnabled = indexPath.section != 0
                return cell
            }
            return UITableViewCell()
        }
        return UITableViewCell()
    }

    func hideKeyboard() {
        self.view.endEditing(true)
    }
}
