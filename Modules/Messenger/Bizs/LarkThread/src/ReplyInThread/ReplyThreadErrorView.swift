//
//  ReplyThreadErrorView.swift
//  LarkThread
//
//  Created by ByteDance on 2022/5/19.
//

import Foundation
import LarkUIKit
import UIKit

protocol ThreadAbnormalStatusView: UIView {
    var backBtn: UIButton? { get }
}

final class ReplyThreadErrorNavigationBar: UIView {
    var backButtonClickedBlock: (() -> Void)?
    let backButton = UIButton(type: .custom)

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backButton.setImage(LarkUIKit.Resources.navigation_back_light, for: .normal)
        backButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
           make.centerY.equalToSuperview()
           make.width.height.equalTo(24)
           make.leading.equalTo(16)
        }

        let titleLabel = UILabel()
        titleLabel.text = BundleI18n.LarkThread.Lark_IM_Thread_ThreadDetail_Title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(48)
            make.right.equalToSuperview().offset(-48)
        }
    }

    @objc
    private func backButtonClicked() {
        backButtonClickedBlock?()
    }
}

final class ReplyThreadErrorView: UIView, ThreadAbnormalStatusView {
    private let backButtonClickedBlock: () -> Void
    private var navBar: ReplyThreadErrorNavigationBar?
    var backBtn: UIButton? {
        return self.navBar?.backButton
    }
    init(backButtonClickedBlock: @escaping () -> Void) {
        self.backButtonClickedBlock = backButtonClickedBlock
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        let clearView = UIView()
        clearView.backgroundColor = UIColor.clear
        addSubview(clearView)
        clearView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.3333)
        }

        let bar = ReplyThreadErrorNavigationBar()
        bar.backButtonClickedBlock = backButtonClickedBlock
        addSubview(bar)
        self.navBar = bar
        bar.snp.makeConstraints { (make) in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        let imageView = UIImageView()
        imageView.image = Resources.replyThreadError
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(100)
            make.top.equalTo(clearView.snp.bottom)
        }
        let label = UILabel()
        /// 返回按钮的问题
        label.text = BundleI18n.LarkThread.Lark_Setting_NameNetworkError
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        addSubview(label)
        label.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(18)
        }
    }
}
