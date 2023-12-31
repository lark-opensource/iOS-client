//
//  UserNickNameSelectFooterView.swift
//  Moment
//
//  Created by liluobin on 2021/5/23.
//

import Foundation
import UIKit
import LarkInteraction

final class UserNickNameSelectFooterView: UICollectionReusableView {
    static let reuseId: String = "UserNickNameSelectFooterView"
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    private lazy var containView = UIView()
    private lazy var refreshBtn: NickNameRefreshButton = {
        let btn = NickNameRefreshButton()
        btn.setImage(Resources.refreshIcon, for: .normal)
        btn.addTarget(self, action: #selector(refreshClick), for: .touchUpInside)
        return btn
    }()

    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Moment.Lark_Community_RefreshNicknames
        label.textColor = UIColor.ud.primaryContentDefault
        label.font = UIFont.systemFont(ofSize: 14)
        label.backgroundColor = .clear
        label.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(refreshClick))
        label.addGestureRecognizer(tap)
        return label
    }()

    var isLoading = false {
        didSet {
            if isLoading {
                showLoading()
            } else {
                hideLoading()
            }
        }
    }
    var refreshCallBack: (() -> Void)?
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor.ud.bgBody
        self.addSubview(containView)
        containView.addPointer(.highlight)
        containView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
        }
        containView.addSubview(refreshBtn)
        containView.addSubview(tipLabel)
        refreshBtn.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        tipLabel.snp.makeConstraints { (make) in
            make.left.equalTo(refreshBtn.snp.right)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }

    }

    @objc
    private func refreshClick() {
        refreshCallBack?()
        showLoading()
    }

    func showLoading() {
        refreshBtn.showLoading(true, bgImage: nil)
    }

    func hideLoading() {
        refreshBtn.showLoading(false, bgImage: nil)
    }

}
