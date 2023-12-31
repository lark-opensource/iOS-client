//
//  AppRankHeader.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2022/3/10.
//

import Foundation
import LarkUIKit
import UIKit

final class AppRankHeader: UICollectionReusableView {
    static let resueId = "WPRankPageHeader"

    private lazy var titleView: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = .clear
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var iconContainer: UIView = {
        UIView()
    }()

    private lazy var explainIcon: UIImageView = {
        let view = UIImageView()
        view.image = Resources.explain_icon.ud.withTintColor(UIColor.ud.iconN3)
        return view
    }()

    var showTipEvent: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: 视图设置
    private func setupViews() {
        addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.height.equalTo(22)
            make.top.equalToSuperview().offset(20)
            make.left.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
        addSubview(iconContainer)
        iconContainer.addSubview(explainIcon)
        iconContainer.snp.makeConstraints { make in
            make.left.equalTo(titleView.snp.right)
            make.centerY.equalTo(titleView.snp.centerY)
            make.width.equalTo(32)
            make.height.equalTo(22)
        }
        explainIcon.snp.makeConstraints { make in
            make.height.width.equalTo(16)
            make.center.equalToSuperview()
        }

        iconContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showTip)))
    }

    func refresh(text: String, showTip: Bool) {
        titleView.text = text
        iconContainer.isHidden = !showTip
        explainIcon.isHidden = !showTip
    }

    @objc
    private func showTip() {
        showTipEvent?()
    }
}
