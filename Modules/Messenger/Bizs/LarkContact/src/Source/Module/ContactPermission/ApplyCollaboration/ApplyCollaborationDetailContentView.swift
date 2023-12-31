//
//  ApplyCollaborationDetailContentView.swift
//  LarkContact
//
//  Created by 姜凯文 on 2020/8/17.
//

import UIKit
import Foundation
import LarkUIKit

final class ApplyCollaborationDetailContentView: UIView {
    private let detailContentViewWidth: CGFloat = Display.typeIsLike == .iPhone5 ? 246 : 300

    private let applyDetailTableView: ApplyCollaborationDetailTableView
    private let applyDetailHeaderView: ApplyCollaborationDetailHeaderView

    init(viewModel: ApplyCollaborationDetailViewModel) {
        self.applyDetailTableView = ApplyCollaborationDetailTableView(viewModel: viewModel)
        self.applyDetailHeaderView = ApplyCollaborationDetailHeaderView(
            userNumber: viewModel.contacts.count
        )
        super.init(frame: .zero)

        self.setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.setupHeaderView()
        self.setupTableView()
    }

    private func setupHeaderView() {
        self.addSubview(applyDetailHeaderView)
        applyDetailHeaderView.snp.makeConstraints { (maker) in
            maker.left.top.right.equalToSuperview()
            maker.height.equalTo(50)
            maker.width.equalTo(detailContentViewWidth)
        }
    }

    private func setupTableView() {
        self.addSubview(applyDetailTableView)
        applyDetailTableView.snp.makeConstraints { (maker) in
            maker.top.equalTo(applyDetailHeaderView.snp.bottom)
            maker.left.equalToSuperview()
            maker.width.equalTo(applyDetailHeaderView)
            maker.height.equalTo(400)
            maker.bottom.equalToSuperview()
        }
    }

    func setDismissBlock(_ dismissBlock: (() -> Void)?) {
        applyDetailHeaderView.dismissBlock = dismissBlock
    }
}

private final class ApplyCollaborationDetailHeaderView: UIView {
    private let titleLabel: UILabel = UILabel()
    private let backButton: UIButton = UIButton()
    private let userNumber: Int

    var dismissBlock: (() -> Void)?

    init(userNumber: Int) {
        self.userNumber = userNumber

        super.init(frame: .zero)

        self.setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.addSubview(backButton)
        backButton.snp.makeConstraints { (maker) in
            maker.left.top.equalToSuperview().inset(19)
            maker.width.equalTo(9)
            maker.height.equalTo(16)
        }

        backButton.setImage(Resources.icon_global_back_black, for: .normal)
        backButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)

        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().inset(14)
            maker.bottom.equalToSuperview().inset(13)
        }

        titleLabel.text = BundleI18n.LarkContact.Lark_NewContacts_PermissionRequestMobileRemoveTitle(self.userNumber)
    }

    @objc
    private func dismiss() {
        self.dismissBlock?()
    }
}
