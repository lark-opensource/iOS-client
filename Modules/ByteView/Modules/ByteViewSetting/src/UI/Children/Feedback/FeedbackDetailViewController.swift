//
//  FeedbackDetailViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2022/8/30.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewCommon
import ByteViewTracker
import ByteViewUI
import UniverseDesignToast

final class FeedbackDetailViewController: SettingViewController {
    private lazy var rightBarButton: UIButton = {
        let button = UIButton()
        button.setTitle(I18n.View_G_SendIssueReport_Button, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(.ud.textLinkNormal, for: .normal)
        button.setTitleColor(.ud.textDisabled, for: .disabled)
        button.addTarget(self, action: #selector(rightBarButtonAction(_:)), for: .touchUpInside)
        button.backgroundColor = .clear
        button.isEnabled = false
        button.addInteraction(type: .highlight)
        return button
    }()

    private var originalContentInset: UIEdgeInsets = .zero
    private var inputIndexPath: IndexPath?

    private var feedbackDetailViewModel: FeedbackDetailViewModel? {
        self.viewModel as? FeedbackDetailViewModel
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.setRightBarButton(UIBarButtonItemFactory.create(customView: rightBarButton), animated: false)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(with:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(with:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapView(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }

    override func viewWillFirstAppear(_ animated: Bool) {
        super.viewWillFirstAppear(animated)
        self.updateRightBarButton()
        self.originalContentInset = self.tableView.contentInset
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let inputCell = cell as? FeedbackInputCell {
            inputCell.delegate = self
            self.inputIndexPath = indexPath
        }
        return cell
    }

    override func reloadData() {
        super.reloadData()
        self.updateRightBarButton()
    }

    @objc private func keyboardWillShow(with notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else { return }

        let keyboardFrameInTableView = tableView.convert(keyboardFrame, from: nil)
        var contentInset = tableView.contentInset
        contentInset.bottom = tableView.frame.height - keyboardFrameInTableView.minY
        tableView.contentInset = contentInset
        tableView.scrollIndicatorInsets = contentInset
        if let indexPath = self.inputIndexPath {
            tableView.scrollToRow(at: indexPath, at: .none, animated: true)
        }
    }

    @objc private func keyboardWillHide(with notification: Notification) {
        tableView.contentInset = self.originalContentInset
        tableView.scrollIndicatorInsets = self.originalContentInset
    }

    private func updateRightBarButton() {
        Util.runInMainThread { [weak self] in
            guard let self = self, let vm = self.feedbackDetailViewModel else { return }
            self.rightBarButton.isEnabled = !self.isSending && vm.isSubmitEnabled
            self.logger.info("rightBarButton.isEnabled = \(self.rightBarButton.isEnabled)")
            if self.isSending {
                self.tableView.alpha = 0.5
                self.tableView.isUserInteractionEnabled = false
                self.rightBarButton.setTitle(I18n.View_G_Sending, for: .normal)
            } else {
                self.tableView.alpha = 1.0
                self.tableView.isUserInteractionEnabled = true
                self.rightBarButton.setTitle(I18n.View_G_SendIssueReport_Button, for: .normal)
            }
        }
    }

    private var isSending = false
    @objc private func rightBarButtonAction(_ sender: Any) {
        self.isSending = true
        self.updateRightBarButton()
        feedbackDetailViewModel?.submit { [weak self] _ in
            Util.runInMainThread {
                guard let self = self, let nav = self.navigationController else { return }
                UDToast.showSuccess(with: I18n.View_G_IssueFeedbackSent, on: nav.view)
                if nav.viewControllers.count > 2 {
                    nav.popToViewController(nav.viewControllers[nav.viewControllers.count - 3], animated: true)
                } else {
                    self.popOrDismiss(true)
                }
            }
        }
    }

    @objc override func doBack() {
        if let vm = self.feedbackDetailViewModel, vm.isDataChanged {
            ByteViewDialog.Builder()
                .title(I18n.View_G_LeaveClearSurePop)
                .leftTitle(I18n.View_G_ContinueEditing_AssignPopUp)
                .leftHandler({ _ in
                    VCTracker.post(name: .vc_meeting_popup_view, params: [.click: "continue", .content: "if_leave_page"])
                })
                .rightTitle(I18n.View_VM_LeaveButton)
                .rightHandler({ [weak self] _ in
                    VCTracker.post(name: .vc_meeting_popup_view, params: [.click: "leave", .content: "if_leave_page"])
                    self?.popOrDismiss(true)
                }).show { _ in
                    VCTracker.post(name: .vc_meeting_popup_view, params: [.content: "if_leave_page"])
                }
        } else {
            super.doBack()
        }
    }

    @objc private func didTapView(_ gr: UITapGestureRecognizer) {
        view.endEditing(true)
    }
}

extension FeedbackDetailViewController: FeedbackInputCellDelegate {
    func feedbackInputCellDidChangeText(_ cell: FeedbackInputCell, text: String) {
        self.feedbackDetailViewModel?.updateDescText(text)
        self.updateRightBarButton()
    }
}
